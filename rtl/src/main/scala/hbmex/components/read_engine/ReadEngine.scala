package hbmex.components.read_engine

import chisel3._
import chisel3.util._
import chisel3.experimental.prefix

import chext.amba.axi4
import axi4.Ops._

import chext.elastic
import elastic.ConnectOp._

import chext.ip.memory
import chisel3.experimental.AffectsChiselPrefix

case class Config(
    val axiMasterCfg: axi4.Config,
    val log2numDesc: Int = 12,
    val rawMemCfg: memory.RawMemConfig = memory.RawMemConfig()
) {
  val numDesc = 1 << log2numDesc
  val wDesc = 64

  require(isPow2(wDesc) && wDesc >= 8)
  require(log2numDesc <= 24)

  assert(axiMasterCfg.read)

  val axiDescCfg = axi4.Config( //
    wAddr = (log2numDesc + log2Ceil(wDesc) - 3),
    wData = wDesc,
    wId = 0
  )
  val axiCtrlCfg = axi4.Config( //
    wAddr = 8,
    wData = 32,
    lite = true
  )
}

class ReadEngine(cfg: Config) extends Module {
  import cfg._

  val genDesc = new Desc
  assert(genDesc.getWidth == wDesc)

  val s_axi_desc = IO(axi4.full.Slave(axiDescCfg))
  val s_axi_ctrl = IO(axi4.lite.Slave(axiCtrlCfg))
  val m_axi = IO(axi4.full.Master(axiMasterCfg))
  val start = IO(Input(Bool()))
  val busy = IO(Output(Bool()))

  private val m_axi_ = m_axi

  private val regBusy = RegInit(false.B)
  busy := regBusy

  private val regCounter = RegInit(0.U(64.W))

  private val regDescIndex = RegInit(0.U(32.W))
  private val regDescCount = RegInit(0.U(32.W))

  private val rdDesc = Wire(new memory.ReadInterface(log2numDesc, wDesc))
  rdDesc.req.noenq()
  rdDesc.resp.nodeq()

  prefix("descMem") {
    import memory._

    val portCfg = PortConfig(
      numOutstandingRead = 1 << log2Ceil(rawMemCfg.latencyRead + 1),
      numOutstandingWrite = 1 << log2Ceil(rawMemCfg.latencyWrite + 1)
    )

    val mem = Module(
      new TrueDualPortRAM( //
        rawMemCfg.copy(wAddr = log2numDesc, wData = wDesc),
        portCfg,
        portCfg.copy(arbiterFunc = () => new ReadOnlyArbiter)
      )
    )
    val bridge = Module(new Axi4FullToReadWriteBridge(axiDescCfg))

    s_axi_desc :=> bridge.s_axi

    bridge.read.req :=> mem.read1.req
    mem.read1.resp :=> bridge.read.resp

    bridge.write.req :=> mem.write1.req
    mem.write1.resp :=> bridge.write.resp

    rdDesc.req :=> mem.read2.req
    mem.read2.resp :=> rdDesc.resp

    mem.write2.req.noenq()
    mem.write2.resp.nodeq()
  }

  private val regBlock = new axi4.lite.components.RegisterBlock(
    wAddr = 8,
    wData = 32,
    wMask = 8 /* TODO: delete wMask later */
  )

  object regs {
    regBlock.base(0)

    // format: off
    val REG_WORKING = regBlock.reg(regBusy, true, false, "REG_WORKING")
    val REG_COUNTER_LO = regBlock.reg(regCounter(31, 0), true, false, "REG_COUNTER_LO")
    val REG_COUNTER_HI = regBlock.reg(regCounter(63, 32), true, false, "REG_COUNTER_HI")

    val REG_DESC_INDEX = regBlock.reg(regDescIndex, true, true, "REG_DESC_INDEX")
    val REG_DESC_COUNT = regBlock.reg(regDescCount, true, true, "REG_DESC_COUNT")

    val CMD_START = regBlock.reserve(4, "CMD_START")
    // format: on

    // TODO uncomment for the register map
    // regBlock.saveRegisterMap("output/", "ReadEngine")
    s_axi_ctrl :=> regBlock.s_axil
  }

  private class Impl extends AffectsChiselPrefix {
    val count = RegInit(0.U(64.W))

    /** The index sent to the descriptor memory as adddress. (stage 1) */
    val stg1_count = RegInit(0.U(64.W))
    val stg1_idx = RegInit(0.U(64.W))

    /** The index of the descriptor in stage 2. */
    val stg2_count = RegInit(0.U(64.W))

    val stg2_complete = stg2_count === 0.U
    val stg2_waitCycles = RegInit(0.U(48.W))

    /** Expected number of R (last) packets to receive in return. */
    val stg3_expected = RegInit(0.U(32.W))
    val stg3_received = RegInit(0.U(32.W))

    val stg3_complete = stg3_expected === stg3_received

    val rvDesc = Wire(Irrevocable(genDesc))
    rvDesc.noenq()
    rvDesc.nodeq()

    def onInit(): Unit = {
      count := regDescCount

      stg1_count := 0.U
      stg1_idx := 0.U

      stg2_count := regDescCount
      stg2_waitCycles := 0.U

      stg3_expected := 0.U
      stg3_received := 0.U

      when(regDescCount === 0.U) {
        regBusy := false.B
      }
    }

    def onWork(): Unit = {
      // Stage 1
      when(stg1_count < count) {
        rdDesc.req.enq(stg1_idx)

        when(rdDesc.req.fire) {
          stg1_idx := stg1_idx + 1.U
          stg1_count := stg1_count + 1.U
        }
      }

      // Stage 2
      when(stg2_waitCycles > 0.U) {
        stg2_waitCycles := stg2_waitCycles - 1.U
      }

      new elastic.Arrival(rdDesc.resp, rvDesc) {
        protected def onArrival: Unit = {
          val desc = Wire(genDesc)
          desc.addr := in(41, 0)
          desc.id := in(53, 42)
          desc.len := in(61, 54)
          desc.flags := in(63, 62)

          out := desc

          dontTouch(desc)

          when(stg2_waitCycles === 0.U) {
            when(desc.flags === Flags.ADDR.U) {
              accept()
              stg3_expected := stg3_expected + 1.U
            }.otherwise {
              consume()
              stg2_waitCycles := desc.addr
            }

            stg2_count := stg2_count - 1.U
          }
        }
      }

      when(rvDesc.valid) {
        val desc = rvDesc.bits

        when(desc.flags === Flags.ADDR.U) {
          val arBits = Wire(chiselTypeOf(m_axi_.ar.bits))

          arBits.addr := desc.addr
          arBits.len := desc.len
          arBits.burst := axi4.BurstType.INCR
          arBits.id := desc.id

          arBits.cache := 0.U
          arBits.prot := 0.U
          arBits.qos := 0.U
          arBits.region := 0.U
          arBits.size := log2Ceil(axiMasterCfg.wData >> 3).U
          arBits.lock := 0.B
          arBits.user := 0.U

          m_axi_.ar.enq(arBits)

          when(m_axi_.ar.fire) {
            rvDesc.deq()
          }
        }.otherwise {
          m_axi_.ar.noenq()
        }
      }

      // stage 3
      m_axi_.r.deq()

      when(m_axi_.r.fire && m_axi_.r.bits.last) {
        stg3_received := stg3_received + 1.U
      }

      when(stg2_complete && stg3_complete) {
        regBusy := false.B
      }
    }
  }

  private val axiStart = regBlock.wrReq && regBlock.wrAddr === regs.CMD_START.U

  when(regBusy) {
    regCounter := regCounter + 1.U
  }

  when(regBlock.wrReq) {
    regBlock.wrOk()
  }

  when(regBlock.rdReq) {
    regBlock.rdOk()
  }

  private val impl = new Impl

  m_axi_.ar.noenq()
  m_axi_.r.nodeq()

  when(regBusy) {
    impl.onWork()
  }.otherwise {
    when(start || axiStart) {
      regBusy := true.B
      regCounter := 0.U
      impl.onInit()
    }
  }

  if (axiMasterCfg.write) {
    m_axi_.aw.noenq()
    m_axi_.w.noenq()
    m_axi_.b.nodeq()
  }
}

case class MultiConfig(
    val numMasters: Int,
    val singleCfg: Config
) {
  require(numMasters >= 1)

  val axiDescCfg = axi4.Config(
    wAddr = singleCfg.axiDescCfg.wAddr + log2Ceil(numMasters),
    wData = singleCfg.axiDescCfg.wData,
    wId = 0
  )

  val axiCtrlCfg = axi4.Config(
    wAddr = singleCfg.axiCtrlCfg.wAddr + log2Ceil(numMasters + 1),
    wData = singleCfg.axiCtrlCfg.wData,
    lite = singleCfg.axiCtrlCfg.lite
  )
}

class ReadEngineMulti(val cfg: MultiConfig) extends Module {
  import cfg._

  val s_axi_desc = IO(axi4.full.Slave(axiDescCfg))
  val s_axi_ctrl = IO(axi4.lite.Slave(axiCtrlCfg))
  val m_axiN = IO(Vec(numMasters, axi4.full.Master(singleCfg.axiMasterCfg)))

  val start = IO(Input(Bool()))
  val busy = IO(Output(Bool()))

  private val regCounter = RegInit(0.U(64.W))

  private val modules = Seq.fill(numMasters) {
    Module(new ReadEngine(singleCfg))
  }

  private val regBlock = new axi4.lite.components.RegisterBlock(
    wAddr = singleCfg.axiCtrlCfg.wAddr,
    wData = singleCfg.axiCtrlCfg.wData,
    wMask = singleCfg.axiCtrlCfg.wAddr /* TODO: delete wMask later? */
  )

  private def interconnectControl(): Unit = prefix("interconnectControl") {
    import axi4.lite.components._

    val demux =
      Module(
        new Demux(
          DemuxConfig(
            axiCtrlCfg,
            numMasters + 1,
            (x: UInt) => (x >> singleCfg.axiCtrlCfg.wAddr)
          )
        )
      )

    s_axi_ctrl :=> demux.s_axil

    demux.m_axil(0) :=> regBlock.s_axil

    for (i <- (0 until numMasters)) {
      demux.m_axil(i + 1) :=> modules(i).s_axi_ctrl
    }
  }
  interconnectControl()

  private def interconnectDesc(): Unit = prefix("interconnectDesc") {
    import axi4.full.components._

    val demux =
      Module(
        new Demux(
          DemuxConfig(
            axiDescCfg,
            numMasters,
            (x: UInt) => (x >> singleCfg.axiDescCfg.wAddr)
          )
        )
      )

    s_axi_desc :=> demux.s_axi

    for (i <- (0 until numMasters)) {
      demux.m_axi(i) :=> modules(i).s_axi_desc
    }
  }
  interconnectDesc()

  private def initMasters(): Unit = {
    modules.map { _.m_axi }.zip(m_axiN).foreach { //
      case (master, slave) => master :=> slave
    }
  }
  initMasters()

  private def initCtrl() = {
    object registerObj {
      regBlock.base(0)

      val REG_WORKING = regBlock.reg(busy, true, false, "REG_WORKING")
      val REG_COUNTER_LO =
        regBlock.reg(regCounter(31, 0), true, false, "REG_COUNTER_LO")
      val REG_COUNTER_HI =
        regBlock.reg(regCounter(63, 32), true, false, "REG_COUNTER_HI")
      val CMD_START = regBlock.reserve(4, "CMD_START")

      // regBlock.saveRegisterMap("output/", "ReadEngineMulti")
    }

    import axi4.lite.components._

    val demux =
      Module(
        new Demux(
          DemuxConfig(
            axiCtrlCfg,
            numMasters + 1,
            (x: UInt) => (x >> singleCfg.axiCtrlCfg.wAddr)
          )
        )
      )

    s_axi_ctrl :=> demux.s_axil
    demux.m_axil(0) :=> regBlock.s_axil

    for (i <- (0 until numMasters)) {
      demux.m_axil(1 + i) :=> modules(i).s_axi_ctrl
    }

    registerObj
  }
  val ctrlRegs = initCtrl()

  busy := VecInit(modules.map(_.busy)).reduceTree(_ || _)
  modules.foreach { _.start := start }

  /* increment the counter when working */
  when(busy) {
    regCounter := regCounter + 1.U
  }

  when(start) {
    regCounter := 0.U
  }

  when(regBlock.wrReq) {
    when(regBlock.wrAddr === ctrlRegs.CMD_START.U) {
      // start in lock step
      modules.foreach { _.start := true.B }
      regCounter := 0.U
    }

    regBlock.wrOk()
  }

  when(regBlock.rdReq) {
    regBlock.rdOk()
  }
}
