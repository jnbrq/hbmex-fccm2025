package hbmex.components.enhance

import chext.amba.axi4
import chext.elastic

import chisel3._
import chisel3.util._
import chisel3.experimental._

import elastic._
import elastic.ConnectOp._

import axi4.Ops._
import axi4.full.{SlaveBuffer, MasterBuffer, WriteDataChannel}

package helpers {

  object IdExtend {
    def read(
        slaveInterfaces: Seq[axi4.full.Interface],
        masterInterfaces: Seq[axi4.full.Interface]
    ): Unit = {
      require(slaveInterfaces.length == masterInterfaces.length)

      slaveInterfaces.zipWithIndex.zip(masterInterfaces).map {
        case ((slave, port), master) => {
          slave.ar :=> master.ar
          master.r :=> slave.r

          master.ar.bits.id := port.U ## slave.ar.bits.id

          require(slave.cfg.read && master.cfg.read)
          require(master.cfg.wId >= slave.cfg.wId + log2Ceil(slaveInterfaces.length))
        }
      }
    }

    def write(
        slaveInterfaces: Seq[axi4.full.Interface],
        masterInterfaces: Seq[axi4.full.Interface]
    ): Unit = {
      require(slaveInterfaces.length == masterInterfaces.length)

      slaveInterfaces.zipWithIndex.zip(masterInterfaces).map {
        case ((slave, port), master) => {
          slave.aw :=> master.aw
          slave.w :=> master.w
          master.b :=> slave.b

          master.aw.bits.id := port.U ## slave.aw.bits.id

          require(slave.cfg.write && master.cfg.write)
          require(master.cfg.wId >= slave.cfg.wId + log2Ceil(slaveInterfaces.length))
        }
      }
    }
  }

}

case class MuxConfig(
    val axiSlaveCfg: axi4.Config,
    val log2numSlaves: Int,
    val arbiterPolicy: Chooser.ChooserFn = Chooser.rr
) {
  require(!axiSlaveCfg.lite)
  require(axiSlaveCfg.read || axiSlaveCfg.write)
  require(log2numSlaves >= 0)

  val numSlaves = 1 << log2numSlaves
  val axiMasterCfg = axiSlaveCfg.copy(wId = axiSlaveCfg.wId + log2numSlaves)
}

class Mux(val cfg: MuxConfig) extends Module {
  import cfg._

  val s_axi = IO(Vec(numSlaves, axi4.full.Slave(axiSlaveCfg)))
  val m_axi = IO(axi4.full.Master(axiMasterCfg))

  private val s_axi_ = {
    val result = Wire(Vec(numSlaves, axi4.full.Interface(axiMasterCfg)))

    if (axiSlaveCfg.read)
      helpers.IdExtend.read(s_axi, result)

    if (axiSlaveCfg.write)
      helpers.IdExtend.write(s_axi, result)

    result
  }
  private val m_axi_ = m_axi

  private val genSelect = UInt(log2numSlaves.W)

  private def implRead(): Unit = prefix("read") {
    def arLogic: Unit = {
      elastic.BasicArbiter(s_axi_.map { _.ar }, m_axi_.ar, arbiterPolicy)
    }

    def rLogic: Unit = {
      val demuxInput = Wire(Irrevocable(m_axi_.r.bits.cloneType))
      val demuxSelect = Wire(Irrevocable(genSelect))

      new Fork(m_axi_.r) {
        protected def onFork: Unit = {
          fork { in } :=> demuxInput
          fork { in.id >> axiSlaveCfg.wId } :=> demuxSelect
        }
      }

      // R channel supports burst interleaving, so no isLastFn
      elastic.Demux(demuxInput, s_axi_.map { _.r }, demuxSelect)
    }

    arLogic
    rLogic
  }

  private def implWrite(): Unit = prefix("write") {
    val portQueue = Module(new Queue(genSelect, 32, flow = true, pipe = true))

    def awLogic: Unit = {
      elastic.BasicArbiter(
        s_axi_.map { _.aw },
        m_axi_.aw,
        arbiterPolicy,
        Some(portQueue.io.enq)
      )
    }

    def wLogic: Unit = {
      // W channel does not support burst interleaving due to the selection logic
      // so isLastFn
      elastic.Mux(
        s_axi_.map { _.w },
        m_axi_.w,
        portQueue.io.deq,
        isLastFn = (x: WriteDataChannel) => x.last
      )
    }

    def bLogic: Unit = {
      val demuxInput = Wire(Irrevocable(m_axi_.b.bits.cloneType))
      val demuxSelect = Wire(Irrevocable(genSelect))

      new Fork(m_axi_.b) {
        protected def onFork: Unit = {
          fork { in } :=> demuxInput
          fork { in.id >> axiSlaveCfg.wId } :=> demuxSelect
        }
      }

      elastic.Demux(demuxInput, s_axi_.map { _.b }, demuxSelect)
    }

    awLogic
    wLogic
    bLogic
  }

  if (axiSlaveCfg.read) implRead()
  if (axiSlaveCfg.write) implWrite()
}

case class DemuxConfig(
    val axiSlaveCfg: chext.amba.axi4.Config,
    val log2numMasters: Int = 4,
    val decodeFn: (UInt) => (UInt),
    val capacityPortQueueW: Int = 8,
    val arbiterPolicy: Chooser.ChooserFn = Chooser.rr
) {
  require(!axiSlaveCfg.lite)
  require(axiSlaveCfg.read || axiSlaveCfg.write)
  require(log2numMasters >= 0)
  require(capacityPortQueueW >= 2)

  val numMasters = 1 << log2numMasters
  val axiMasterCfg = axiSlaveCfg
}

class Demux(val cfg: DemuxConfig) extends Module {
  import cfg._

  val s_axi = IO(axi4.full.Slave(axiSlaveCfg))
  val m_axi = IO(Vec(numMasters, axi4.full.Master(axiMasterCfg)))

  private val s_axi_ = s_axi
  private val m_axi_ = m_axi

  private val genSelect = UInt(log2numMasters.W)

  private def implRead(): Unit = prefix("read") {
    def arLogic: Unit = {
      val demuxInput = Wire(Irrevocable(axi4.full.ReadAddressChannel(axiMasterCfg)))
      val demuxSelect = Wire(Irrevocable(genSelect))

      new elastic.Fork(s_axi_.ar) {
        override protected def onFork = {
          fork() :=> demuxInput
          fork(decodeFn(in.addr)) :=> demuxSelect
        }
      }

      elastic.Demux(
        demuxInput,
        m_axi_.map { _.ar },
        demuxSelect
      )
    }

    def rLogic: Unit = {
      val r = Wire(Vec(numMasters, Irrevocable(axi4.full.ReadDataChannel(axiMasterCfg))))

      m_axi_.map { _.r }.zip(r).foreach { //
        case (source, sink) => source :=> sink
      }

      // R channel supports burst interleaving, so no isLastFn
      elastic.BasicArbiter(
        r,
        s_axi_.r,
        arbiterPolicy
      )
    }

    arLogic
    rLogic
  }

  private def implWrite(): Unit = prefix("write") {
    val portQueue = Module(
      new Queue(
        genSelect,
        capacityPortQueueW,
        flow = true,
        pipe = true
      )
    )

    def awLogic: Unit = {
      val demuxInput = Wire(Irrevocable(axi4.full.WriteAddressChannel(axiMasterCfg)))
      val demuxSelect = Wire(Irrevocable(genSelect))

      new elastic.Fork(s_axi_.aw) {
        override protected def onFork = {
          fork() :=> demuxInput
          fork(decodeFn(in.addr)) :=> demuxSelect
          fork(decodeFn(in.addr)) :=> portQueue.io.enq
        }
      }

      elastic.Demux(demuxInput, m_axi_.map { _.aw }, demuxSelect)
    }

    def wLogic: Unit = {
      // W channel does not support burst interleaving due to the selection logic
      // so isLastFn
      elastic.Demux(
        s_axi_.w,
        m_axi_.map { _.w },
        portQueue.io.deq,
        isLastFn = (x: WriteDataChannel) => x.last
      )
    }

    def bLogic: Unit = {
      val b = Wire(Vec(numMasters, Irrevocable(axi4.full.WriteResponseChannel(axiMasterCfg))))

      m_axi_.map { _.b }.zip(b).foreach { //
        case (source, sink) => source :=> sink
      }

      elastic.BasicArbiter(
        b,
        s_axi_.b,
        arbiterPolicy
      )
    }

    awLogic
    wLogic
    bLogic
  }

  if (axiSlaveCfg.read)
    implRead()
  if (axiSlaveCfg.write)
    implWrite()
}

case class IdSerializeConfig(
    val axiSlaveCfg: axi4.Config,
    val capacityIdQueueR: Int = 4,
    val capacityIdQueueW: Int = 4
) {
  require(!axiSlaveCfg.lite)
  require(axiSlaveCfg.read || axiSlaveCfg.write)

  val axiMasterCfg = axiSlaveCfg.copy(wId = 0)
}

/** Serializes the AXI transactions to a single ID, which is 0.
  *
  * @param axiCfg
  *   AXI configuration of the slave interface.
  */
class IdSerialize(val cfg: IdSerializeConfig) extends Module {
  import cfg._

  val s_axi = IO(axi4.full.Slave(axiSlaveCfg))
  val m_axi = IO(axi4.full.Master(axiMasterCfg))

  private val genId = UInt(axiSlaveCfg.wId.W)

  private def implRead(): Unit = prefix("read") {
    val idQueue = Module(
      new Queue(
        genId,
        cfg.capacityIdQueueR,
        flow = true,
        pipe = true
      )
    )

    idQueue.io.deq.nodeq()

    new Fork(s_axi.ar) {
      protected def onFork: Unit = {
        new Replicate(fork(in), idQueue.io.enq) {
          protected def onReplicate: Unit = {
            len := in.len +& 1.U
            out := in.id
          }
        }

        fork(in) :=> m_axi.ar
      }
    }

    new Transform(m_axi.r, s_axi.r) {
      protected def onTransform: Unit = {
        out := in
        out.id := idQueue.io.deq.bits
      }
    }

    when(s_axi.r.fire) {
      idQueue.io.deq.deq()
    }
  }

  private def implWrite(): Unit = prefix("write") {
    val idQueue = Module(
      new Queue(
        genId,
        cfg.capacityIdQueueR,
        flow = true,
        pipe = true
      )
    )

    new Fork(s_axi.aw) {
      protected def onFork: Unit = {
        fork(in.id) :=> idQueue.io.enq
        fork(in) :=> m_axi.aw
      }
    }

    s_axi.w :=> m_axi.w

    new Join(s_axi.b) {
      protected def onJoin: Unit = {
        val id = join(idQueue.io.deq)

        out := join(m_axi.b)
        out.id := id
      }
    }
  }

  if (axiSlaveCfg.read)
    implRead()

  if (axiMasterCfg.write)
    implWrite()
}

/** The idea of this class to programmatically connect a large number of sequentially arranged components that expose AXI ports.
  *
  * @todo
  *   Why not generalize this idea once we have a connectable interface?
  */
class AxiFullStages(val stagebufferCfg: axi4.BufferConfig = axi4.BufferConfig.all(2)) {
  private type Interface = axi4.full.Interface
  import scala.collection.mutable.ArrayBuffer

  private class Stage(val name: String) {
    val slaveInterfaces: ArrayBuffer[Interface] = ArrayBuffer.empty
    val masterInterfaces: ArrayBuffer[Interface] = ArrayBuffer.empty
  }

  private val stages: ArrayBuffer[Stage] = ArrayBuffer.empty
  private val masterInterfaces: ArrayBuffer[Interface] = ArrayBuffer.empty
  private val slaveInterfaces: ArrayBuffer[Interface] = ArrayBuffer.empty

  def newStage(stageName: String = ""): Unit = {
    stages.addOne(new Stage(stageName))
  }

  def addSlaveInterface(interface: Interface): Unit = {
    if (stages.isEmpty) {
      slaveInterfaces.addOne(interface)
    } else {
      stages.last.slaveInterfaces.addOne(interface)
    }
  }

  def addMasterInterface(interface: Interface): Unit = {
    if (stages.isEmpty) {
      masterInterfaces.addOne(interface)
    } else {
      stages.last.masterInterfaces.addOne(interface)
    }
  }

  def addSlaveInterfaces(interface: Seq[Interface]): Unit = {
    if (stages.isEmpty) {
      slaveInterfaces.addAll(interface)
    } else {
      stages.last.slaveInterfaces.addAll(interface)
    }
  }

  def addMasterInterfaces(interface: Seq[Interface]): Unit = {
    if (stages.isEmpty) {
      masterInterfaces.addAll(interface)
    } else {
      stages.last.masterInterfaces.addAll(interface)
    }
  }

  def connectAll(): Unit = {
    var currentStage = 0
    var currentMasterInterfaces = masterInterfaces.toSeq

    stages.foreach { stage =>
      {
        val currentSlaveInterfaces = stage.slaveInterfaces.toSeq
        assert(
          currentMasterInterfaces.length == currentSlaveInterfaces.length,
          f"Interface lengths do not match at stage $currentStage with name ${stage.name}! (${currentMasterInterfaces.length} != ${currentSlaveInterfaces.length})"
        )

        currentMasterInterfaces.zip(currentSlaveInterfaces).foreach {
          case (master, slave) => {
            master :=> axi4.full.MasterBuffer(slave, stagebufferCfg)
          }
        }

        currentMasterInterfaces = stage.masterInterfaces.toSeq

        currentStage += 1
      }
    }

    val currentSlaveInterfaces = slaveInterfaces.toSeq
    assert(
      currentMasterInterfaces.length == currentSlaveInterfaces.length,
      f"Interface lengths do not match on the master-side! (${currentMasterInterfaces.length} != ${currentSlaveInterfaces.length})"
    )

    currentMasterInterfaces.zip(currentSlaveInterfaces).foreach {
      case (master, slave) => {
        master :=> slave
      }
    }
  }
}
