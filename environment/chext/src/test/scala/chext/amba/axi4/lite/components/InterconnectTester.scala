package chext.amba.axi4.lite.components

import chisel3._
import chisel3.util._

import chiseltest._

import chext.amba.axi4
import chext.test.Expect

trait InterconnectHelper[M <: Module] {
  def slaveInterfaces(module: M): Seq[axi4.lite.Interface]
  def masterInterfaces(module: M): Seq[axi4.lite.Interface]
}

abstract class InterconnectTester[T <: Module](
    val dut: T,
    val logEnabled: Boolean = true
)(implicit val helper: InterconnectHelper[T])
    extends chext.test.TestMixin {

  private val slaveInterfaces = helper.slaveInterfaces(dut)
  private val masterInterfaces = helper.masterInterfaces(dut)

  private var counter = 0

  private val slaveIdWidth = 5
  private val slaveIdMask = (1 << slaveIdWidth) - 1

  require(slaveInterfaces.length < 32, "Slave ID must be encoded in 5 bits.")

  val axiSlaveConfig = slaveInterfaces(0).cfg
  require(slaveInterfaces.forall { _.cfg == axiSlaveConfig })

  val axiMasterConfig = masterInterfaces(0).cfg
  require(masterInterfaces.forall { _.cfg == axiMasterConfig })

  require(axiSlaveConfig == axiMasterConfig)

  val numThreads = slaveInterfaces.length

  import scala.collection.mutable.Queue

  import axi4.lite._
  import axi4.lite.test._
  import axi4.lite.test.PacketUtils._

  slaveInterfaces.foreach { _.initSlave() }
  masterInterfaces.foreach { _.initMaster() }

  class ThreadInfo {
    val arTaskQueue = Queue.empty[AddressPacket]
    val rTaskQueue = Queue.empty[ReadDataPacket]
    val awTaskQueue = Queue.empty[AddressPacket]
    val wTaskQueue = Queue.empty[WriteDataPacket]
    val bTaskQueue = Queue.empty[WriteResponsePacket]

    val arExpectedQueue = Queue.empty[AddressPacket]
    val rExpectedQueue = Queue.empty[ReadDataPacket]
    val awExpectedQueue = Queue.empty[AddressPacket]
    val wExpectedQueue = Queue.empty[WriteDataPacket]
    val bExpectedQueue = Queue.empty[WriteResponsePacket]
  }

  class MasterInfo {
    var arReceiveCount = 0
    var awReceiveCount = 0
    var wReceiveCount = 0
  }

  class SlaveInfo {
    var rReceiveCount = 0
    var bReceiveCount = 0
  }

  protected def log(x: String) =
    if (logEnabled) println(f"[t = ${counter}%6d] $x")

  protected def logSlave(
      slaveIdx: Int,
      event: String,
      o: Object = null
  ): Unit = {
    val objString = if (o != null) o.toString() else ""
    log(f"[Slave ${slaveIdx}] ${event} ${objString}")
  }

  protected def logMaster(
      masterIdx: Int,
      event: String,
      o: Object = null
  ): Unit = {
    val objString = if (o != null) o.toString() else ""
    log(f"[Master ${masterIdx}] ${event} ${objString}")
  }

  val threadInfos = Array.fill(numThreads) { new ThreadInfo }
  val masterInfos = Array.fill(masterInterfaces.length) { new MasterInfo }
  val slaveInfos = Array.fill(slaveInterfaces.length) { new SlaveInfo }

  private def handleMaster(masterIdx: Int) = {
    val master = masterInterfaces(masterIdx)
    val masterInfo = masterInfos(masterIdx)

    fork {
      while (masterInfo.arReceiveCount > 0) {
        logMaster(
          masterIdx,
          f"Remaining AR packets = ${masterInfo.arReceiveCount}"
        )
        logMaster(masterIdx, "waiting for read address")
        val arPacket = master.receiveReadAddress()
        val threadInfo = threadInfos(arPacket.addr.toInt & slaveIdMask)

        logMaster(masterIdx, "received read address", arPacket)

        assert(
          threadInfo.arExpectedQueue.nonEmpty,
          "threadInfo.arExpectedQueue.nonEmpty"
        )
        Expect.equals(threadInfo.arExpectedQueue.head, arPacket)
        threadInfo.arExpectedQueue.removeHead()

        assert(threadInfo.rTaskQueue.nonEmpty, "threadInfo.rTaskQueue.nonEmpty")
        val rNext = threadInfo.rTaskQueue.head
        threadInfo.rTaskQueue.removeHead()
        threadInfo.rExpectedQueue.addOne(rNext)

        stepRandom(16)
        logMaster(masterIdx, "send read data", rNext)
        master.sendReadData(rNext)

        masterInfo.arReceiveCount -= 1
      }
    }.fork {
      while (masterInfo.awReceiveCount > 0 || masterInfo.wReceiveCount > 0) {
        logMaster(
          masterIdx,
          f"Remaining AW packets = ${masterInfo.awReceiveCount}, W packets = ${masterInfo.wReceiveCount}"
        )

        var awPacket_ = Option.empty[AddressPacket]
        var wPacket_ = Option.empty[WriteDataPacket]

        fork {
          logMaster(masterIdx, "waiting for write address")
          awPacket_ = Some(master.receiveWriteAddress())
          logMaster(masterIdx, "received write address", awPacket_.get)

          masterInfo.awReceiveCount -= 1
        }.fork {
          logMaster(masterIdx, "waiting for write data")
          wPacket_ = Some(master.receiveWriteData())
          logMaster(masterIdx, "received write data", wPacket_.get)

          masterInfo.wReceiveCount -= 1
        }.join()

        val awPacket = awPacket_.get
        val wPacket = wPacket_.get

        val threadInfo = threadInfos(awPacket.addr.toInt & slaveIdMask)
        Expect.equals(
          (awPacket.addr & slaveIdMask),
          (wPacket.data & slaveIdMask),
          "awPacket and wPacket must come from the same slave."
        )

        assert(
          threadInfo.awExpectedQueue.nonEmpty,
          "threadInfo.awExpectedQueue.nonEmpty"
        )
        Expect.equals(threadInfo.awExpectedQueue.head, awPacket)
        threadInfo.awExpectedQueue.removeHead()

        assert(
          threadInfo.wExpectedQueue.nonEmpty,
          "threadInfo.wExpectedQueue.nonEmpty"
        )
        Expect.equals(threadInfo.wExpectedQueue.head, wPacket)
        threadInfo.wExpectedQueue.removeHead()

        assert(threadInfo.bTaskQueue.nonEmpty, "threadInfo.bTaskQueue.nonEmpty")
        val bNext = threadInfo.bTaskQueue.head
        threadInfo.bTaskQueue.removeHead()
        threadInfo.bExpectedQueue.addOne(bNext)

        stepRandom(16)
        logMaster(masterIdx, "send write response", bNext)
        master.sendWriteResponse(bNext)
      }
    }.join()

    logMaster(masterIdx, "Complete.")
  }

  private def handleSlave(slaveIdx: Int) = {
    val slave = slaveInterfaces(slaveIdx)
    val slaveInfo = slaveInfos(slaveIdx)

    fork {
      val threadInfo = threadInfos(slaveIdx)
      var done = false

      while (!done) {
        var sentAny = false
        val popNum = 1 + rand.nextInt(4 /* TODO make reconfigurable */ )

        for (i <- (0 until popNum)) {
          if (threadInfo.arTaskQueue.nonEmpty) {
            val arNext = threadInfo.arTaskQueue.head
            threadInfo.arTaskQueue.removeHead()
            threadInfo.arExpectedQueue.addOne(arNext)
            logSlave(slaveIdx, "send read address", arNext)
            slave.sendReadAddress(arNext)
            stepRandom(4)

            sentAny = true
          }
        }

        done = !sentAny
        stepRandom(4)
      }
    }.fork {
      val threadInfo = threadInfos(slaveIdx)
      while (slaveInfo.rReceiveCount > 0) {
        logSlave(slaveIdx, f"Remaining R packets: ${slaveInfo.rReceiveCount}")
        logSlave(slaveIdx, "waiting for read data")
        val rPacket = slave.receiveReadData()
        logSlave(slaveIdx, "received read data", rPacket)

        val threadInfo = threadInfos(slaveIdx)

        assert(
          threadInfo.rExpectedQueue.nonEmpty,
          "threadInfo.rExpectedQueue.nonEmpty"
        )
        Expect.equals(threadInfo.rExpectedQueue.head, rPacket)
        threadInfo.rExpectedQueue.removeHead()

        stepRandom(4)

        slaveInfo.rReceiveCount -= 1
      }
    }.fork {
      val threadInfo = threadInfos(slaveIdx)
      var done = false

      while (!done) {
        var sentAny = false
        val popNum = 1 + rand.nextInt(4 /* TODO make reconfigurable */ )

        for (i <- (0 until popNum)) {
          if (threadInfo.awTaskQueue.nonEmpty) {
            val awNext = threadInfo.awTaskQueue.head
            threadInfo.awTaskQueue.removeHead()
            threadInfo.awExpectedQueue.addOne(awNext)

            assert(
              threadInfo.wTaskQueue.nonEmpty,
              "threadInfo.wTaskQueue.nonEmpty"
            )
            val wNext = threadInfo.wTaskQueue.head
            threadInfo.wTaskQueue.removeHead()
            threadInfo.wExpectedQueue.addOne(wNext)
            fork {
              logSlave(slaveIdx, "send write address", awNext)
              slave.sendWriteAddress(awNext)
            }.fork {
              logSlave(slaveIdx, "send write data", wNext)
              slave.sendWriteData(wNext)
            }.join()
            stepRandom(4)

            sentAny = true
          }
        }

        done = !sentAny
        stepRandom(4)
      }
    }.fork {
      val threadInfo = threadInfos(slaveIdx)
      while (slaveInfo.bReceiveCount > 0) {
        logSlave(slaveIdx, f"Remaining B packets: ${slaveInfo.bReceiveCount}")
        logSlave(slaveIdx, "waiting for write response")
        val bPacket = slave.receiveWriteResponse()
        logSlave(slaveIdx, "received write response", bPacket)
        assert(
          threadInfo.bExpectedQueue.nonEmpty,
          "threadInfo.bExpectedQueue.nonEmpty"
        )
        Expect.equals(threadInfo.bExpectedQueue.head, bPacket)
        threadInfo.bExpectedQueue.removeHead()

        stepRandom(4)

        slaveInfo.bReceiveCount -= 1
      }
    }.join()

    logSlave(slaveIdx, "Complete.")
  }

  protected def readTask(
      slaveIdx: Int,
      masterIdx: Int,
      addr: Int
  ): Unit = {
    val slaveInfo = slaveInfos(slaveIdx)
    val masterInfo = masterInfos(masterIdx)

    require(
      (addr & slaveIdMask) == 0,
      f"Lower ${slaveIdWidth} bits of the address is used to encode the slave ID. They must be zero."
    )
    val threadInfo = threadInfos(slaveIdx)
    threadInfo.arTaskQueue.addOne(AddressPacket(addr | slaveIdx))
    threadInfo.rTaskQueue.addOne(
      ReadDataPacket(
        (rand.nextInt(0x7fff_ffff) & ~slaveIdMask) | slaveIdx
      )
    )

    slaveInfo.rReceiveCount += 1
    masterInfo.arReceiveCount += 1
  }

  protected def writeTask(
      slaveIdx: Int,
      masterIdx: Int,
      addr: Int
  ): Unit = {
    val slaveInfo = slaveInfos(slaveIdx)
    val masterInfo = masterInfos(masterIdx)

    require(
      (addr & slaveIdMask) == 0,
      f"Lower ${slaveIdWidth} bits of the address is used to encode the slave ID. They must be zero."
    )
    val threadInfo = threadInfos(slaveIdx)
    threadInfo.awTaskQueue.addOne(AddressPacket(addr | slaveIdx))
    threadInfo.wTaskQueue.addOne(
      WriteDataPacket(
        (rand.nextInt(0x7fff_ffff) & ~slaveIdMask) | slaveIdx
      )
    )
    threadInfo.bTaskQueue.addOne(WriteResponsePacket())

    slaveInfo.bReceiveCount += 1
    masterInfo.awReceiveCount += 1
    masterInfo.wReceiveCount += 1
  }

  protected def createTasks(): Unit

  def run() = {
    import chiseltest.internal.Context

    createTasks()

    var mastersComplete = false
    var slavesComplete = false

    fork {
      val masterThreads = masterInterfaces.zipWithIndex.map {
        case (master, idx) => {
          Context().backend.doFork(
            () => handleMaster(idx),
            Some(f"master_$idx"),
            None
          )
        }
      }
      Context().backend.doJoin(masterThreads, false)
      mastersComplete = true
    }.fork {
      val slaveThreads = slaveInterfaces.zipWithIndex.map {
        case (slave, idx) => {
          Context().backend.doFork(
            () => handleSlave(idx),
            Some(f"slave_$idx"),
            None
          )
        }
      }
      Context().backend.doJoin(slaveThreads, false)
      slavesComplete = true
    }.fork {
      while (!mastersComplete || !slavesComplete) {
        counter += 1
        step(1)
      }
    }.join()
  }
}
