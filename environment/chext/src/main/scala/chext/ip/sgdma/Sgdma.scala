package chext.ip.sgdma

import chisel3._
import chisel3.util._

import chisel3.experimental.prefix

import chext.amba.axi4
import chext.elastic
import chext.ip.memory

import axi4.Ops._
import elastic.ConnectOp._
import chisel3.experimental.AffectsChiselPrefix

class SgdmaDesc extends Bundle {

  /** addr for GEN_AR/AW, wait cycles for WAIT */
  val addr = UInt(48.W)

  val len = UInt(10.W)
  val flags = UInt(6.W)
}

object SgdmaFlags {
  val _GEN_WAIT = 0x0.toLong
  val _GEN_PKT = 0x1.toLong
  val _GEN_AW = 0x2.toLong

  val GEN_AR = _GEN_PKT
  val GEN_AW = _GEN_PKT | _GEN_AW
  val WAIT = _GEN_WAIT
}

object SgdmaMode {
  val SGDMA = 0x0.toLong // 0b0000
  val INIT_CONST = 0x1.toLong // 0b0001
  val INIT_LINEAR = 0x5.toLong // 0b0101
  val INIT_ZERO = 0xd.toLong // 0b1101
}

case class SgdmaConfig(
    val axiMasterCfg: axi4.Config,
    val log2numDesc: Int = 12,
    val rawMemCfg: memory.RawMemConfig = memory.RawMemConfig(),
    val writeBufferCfg: Option[WriteBufferConfig] = Some(WriteBufferConfig())
) {
  val numDesc = 1 << log2numDesc
  val wDesc = 64

  require(isPow2(wDesc) && wDesc >= 8)
  require(log2numDesc <= 24)

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

class Sgdma(cfg: SgdmaConfig) extends Module {
  import cfg._

  val genDesc = new SgdmaDesc
  assert(genDesc.getWidth == cfg.wDesc)

  val s_axi_desc = IO(axi4.full.Slave(axiDescCfg))
  val s_axil_ctrl = IO(axi4.lite.Slave(axiCtrlCfg))
  val m_axi = IO(axi4.full.Master(axiMasterCfg))

  private val m_axi_ = Wire(axi4.full.Interface(axiMasterCfg))
  if (writeBufferCfg.nonEmpty)
    WriteBuffer(m_axi_, m_axi, writeBufferCfg.get)
  else
    m_axi_ :=> m_axi

  val start = IO(Input(Bool()))
  val busy = IO(Output(Bool()))

  /* is DMA busy? */
  private val working = RegInit(false.B)
  busy := working

  /* counts while busy */
  private val regCounter = RegInit(0.U(64.W))

  /* task mode */
  private val regMode = RegInit(SgdmaMode.SGDMA.U(8.W))

  /* addresses the descriptors */
  private val regSgdmaIndexLO = RegInit(0.U(32.W))
  private val regSgdmaIndexHI = RegInit(0.U(32.W))

  private val regSgdmaLengthLO = RegInit(0.U(32.W))
  private val regSgdmaLengthHI = RegInit(0.U(32.W))

  private val regSgdmaDiscardReadData = RegInit(false.B)

  /* these registers define the initialization target memory */
  private val regInitAddrLO = RegInit(0.U(32.W))
  private val regInitAddrHI = RegInit(0.U(32.W))

  private val regInitSizeLO = RegInit(0.U(32.W))
  private val regInitSizeHI = RegInit(0.U(32.W))

  private val regInitMaxBurstLen = RegInit(32.U(32.W))

  /* these registers are used with constant and linear initialization */
  private val regInitInitial = RegInit(VecInit(Seq.fill(4) { 0.U(32.W) }))
  private val regInitDelta = RegInit(VecInit(Seq.fill(4) { 0.U(32.W) }))

  private val read_desc = Wire(new memory.ReadInterface(log2numDesc, wDesc))
  dontTouch(read_desc)

  read_desc.req.noenq()
  read_desc.resp.nodeq()

  private def initSgdma(): Unit = prefix("initSgdma") {
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

    // TODO: find a better way to replace <>
    bridge.read <> mem.read1
    bridge.write <> mem.write1

    // TODO: find a better way to replace <>
    read_desc <> mem.read2

    mem.write2.req.noenq()
    mem.write2.resp.nodeq()
  }
  initSgdma()

  private val regBlock = new axi4.lite.components.RegisterBlock(
    wAddr = 8,
    wData = 32,
    wMask = 8 /* TODO: delete wMask later */
  )

  private def initCtrl() = prefix("ctrl") {
    object registerObj {
      regBlock.base(0)

      val REG_WORKING = regBlock.reg(working, true, false, "REG_WORKING")
      val REG_COUNTER_LO = regBlock.reg(regCounter(31, 0), true, false, "REG_COUNTER_LO")
      val REG_COUNTER_HI = regBlock.reg(regCounter(63, 32), true, false, "REG_COUNTER_HI")

      val REG_MODE = regBlock.reg(regMode, true, true, "REG_MODE")
      val REG_DISCARD_READ_DATA =
        regBlock.reg(regSgdmaDiscardReadData, true, true, "REG_SGDMA_DISCARD_READ_DATA")

      val REG_DESC_INDEX_LO = regBlock.reg(regSgdmaIndexLO, true, true, "REG_SGDMA_INDEX_LO")
      val REG_DESC_INDEX_HI = regBlock.reg(regSgdmaIndexHI, true, true, "REG_SGDMA_INDEX_HI")

      val REG_DESC_LENGTH_LO = regBlock.reg(regSgdmaLengthLO, true, true, "REG_SGDMA_LENGTH_LO")
      val REG_DESC_LENGTH_HI = regBlock.reg(regSgdmaLengthHI, true, true, "REG_SGDMA_LENGTH_HI")

      val REG_INIT_ADDR_LO = regBlock.reg(regInitAddrLO, true, true, "REG_INIT_ADDR_LO")
      val REG_INIT_ADDR_HI = regBlock.reg(regInitAddrHI, true, true, "REG_INIT_ADDR_HI")

      val REG_INIT_SIZE_LO = regBlock.reg(regInitSizeLO, true, true, "REG_INIT_SIZE_LO")
      val REG_INIT_SIZE_HI = regBlock.reg(regInitSizeHI, true, true, "REG_INIT_SIZE_HI")

      val REG_INIT_MAX_BURST_LEN =
        regBlock.reg(regInitMaxBurstLen, true, true, "REG_INIT_MAX_BURST_LEN")

      val REG_VALUE_INIT_BASE = regBlock.nextAddr

      regInitInitial.zipWithIndex.foreach { //
        case (reg, idx) => regBlock.reg(reg, true, true, f"REG_INIT_INITIAL_$idx")
      }

      val REG_VALUE_DELTA_BASE = regBlock.nextAddr

      regInitDelta.zipWithIndex.foreach { //
        case (reg, idx) => regBlock.reg(reg, true, true, f"REG_INIT_DELTA_$idx")
      }

      val CMD_START = regBlock.reserve(4, "CMD_START")

      // regBlock.saveRegisterMap("output/", "SGDMA")
      s_axil_ctrl :=> regBlock.s_axil
    }

    registerObj
  }

  val ctrlRegs = initCtrl()

  /** Asserted in case of an AXI start request. */
  private val axiStart = regBlock.wrReq && regBlock.wrAddr === ctrlRegs.CMD_START.U

  /* increment the counter when working */
  when(working) {
    regCounter := regCounter + 1.U
  }

  when(regBlock.wrReq) {
    regBlock.wrOk()
  }

  when(regBlock.rdReq) {
    regBlock.rdOk()
  }

  private class sgdmaImpl extends AffectsChiselPrefix {
    val count = RegInit(0.U(64.W))
    val discardReadData = RegInit(false.B)

    /** The index sent to the descriptor memory as adddress. (stage 1) */
    val stg1_count = RegInit(0.U(64.W))
    val stg1_idx = RegInit(0.U(64.W))

    /** The index of the descriptor in stage 2. */
    val stg2_count = RegInit(0.U(64.W))

    val stg2_complete = stg2_count === 0.U
    val stg2_waitCycles = RegInit(0.U(48.W))

    /** Expected number of B or R (last) packets to receive in return. */
    val stg3_expected = RegInit(0.U(32.W))
    val stg3_wBeatCount = RegInit(0.U(16.W))

    val stg3_received = RegInit(0.U(32.W))
    val stg3_complete = stg3_expected === stg3_received

    val rvDesc = Wire(Irrevocable(genDesc))
    rvDesc.noenq()
    rvDesc.nodeq()

    val rvAW = Wire(chiselTypeOf(m_axi_.aw))
    rvAW.noenq()
    rvAW.nodeq()

    /** Sent AW packets are used for generating the WLAST signal. */
    val queueAW = Module(new Queue(chiselTypeOf(m_axi_.aw.bits), 16))
    queueAW.io.enq.noenq()
    queueAW.io.deq.nodeq()

    val stg3_wBeatLast = Wire(Bool())
    stg3_wBeatLast := stg3_wBeatCount === queueAW.io.deq.bits.len

    def init(): Unit = {
      val countNext = Cat(regSgdmaLengthHI, regSgdmaLengthLO)

      count := countNext
      discardReadData := regSgdmaDiscardReadData

      stg1_count := 0.U
      stg1_idx := 0.U

      stg2_count := countNext
      stg2_waitCycles := 0.U

      stg3_expected := 0.U
      stg3_received := 0.U

      when(countNext === 0.U) {
        working := false.B
      }
    }

    def work(): Unit = {
      // Stage 1
      when(stg1_count < count) {
        read_desc.req.enq(stg1_idx)

        when(read_desc.req.fire) {
          stg1_idx := stg1_idx + 1.U
          stg1_count := stg1_count + 1.U
        }
      }

      // Stage 2
      when(stg2_waitCycles > 0.U) {
        stg2_waitCycles := stg2_waitCycles - 1.U
      }

      new elastic.Arrival(read_desc.resp, rvDesc) {
        protected def onArrival: Unit = {
          val desc = Wire(genDesc)

          desc.addr := in(47, 0)
          desc.len := in(57, 48)
          desc.flags := in(63, 58)

          out := desc

          dontTouch(desc)

          when(stg2_waitCycles === 0.U) {
            when(desc.flags === SgdmaFlags.GEN_AR.U || desc.flags === SgdmaFlags.GEN_AW.U) {
              when(discardReadData) {
                when(desc.flags === SgdmaFlags.GEN_AR.U) {
                  accept()
                  stg3_expected := stg3_expected + 1.U
                }.otherwise {
                  consume()
                }
              }.otherwise {
                accept()

                when(desc.flags === SgdmaFlags.GEN_AW.U) {
                  stg3_expected := stg3_expected + 1.U
                }
              }
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

        when(desc.flags === SgdmaFlags.GEN_AR.U) {
          val arBits = Wire(chiselTypeOf(m_axi_.ar.bits))

          arBits.addr := desc.addr
          arBits.len := desc.len
          arBits.burst := axi4.BurstType.INCR
          arBits.id := 0.U

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
        }.elsewhen(desc.flags === SgdmaFlags.GEN_AW.U) {
          when(discardReadData) {
            rvDesc.deq()
          }.otherwise {
            when(rvDesc.valid) {
              val awBits = Wire(chiselTypeOf(m_axi_.aw.bits))

              awBits.addr := desc.addr
              awBits.len := desc.len
              awBits.burst := axi4.BurstType.INCR
              awBits.id := 0.U

              awBits.cache := 0.U
              awBits.prot := 0.U
              awBits.qos := 0.U
              awBits.region := 0.U
              awBits.size := log2Ceil(axiMasterCfg.wData >> 3).U
              awBits.lock := 0.B
              awBits.user := 0.U

              rvAW.enq(awBits)
            }

            when(rvAW.fire) {
              rvDesc.deq()
            }
          }
        }
      }

      new elastic.Fork(rvAW) {
        protected def onFork: Unit = {
          fork() :=> m_axi_.aw
          fork() :=> queueAW.io.enq
        }
      }

      // Stage 3
      when(discardReadData) {
        m_axi_.r.deq()

        when(m_axi_.r.fire && m_axi_.r.bits.last) {
          stg3_received := stg3_received + 1.U
        }
      }.otherwise {
        new elastic.Arrival(m_axi_.r, m_axi_.w) {
          protected def onArrival: Unit = {
            out.data := in.data
            out.last := stg3_wBeatLast
            out.strb := (-1).S(axiMasterCfg.wStrobe.W).asUInt
            out.user := in.user

            /* do not accept unless we know that a packet is valid */
            when(queueAW.io.deq.valid) {
              when(stg3_wBeatLast) {
                queueAW.io.deq.deq()
                stg3_wBeatCount := 0.U
              }.otherwise {
                stg3_wBeatCount := stg3_wBeatCount + 1.U
              }

              accept()
            }.otherwise {
              noAccept()
            }
          }
        }

        m_axi_.b.deq()

        when(m_axi_.b.fire) {
          stg3_received := stg3_received + 1.U
        }
      }

      when(stg2_complete && stg3_complete) {
        working := false.B
      }
    }
  }

  private val sgdma = new sgdmaImpl

  private class initImpl extends AffectsChiselPrefix {
    //

    def init(): Unit = {
      //
    }

    def work(): Unit = {
      working := false.B
    }
  }

  private val init = new initImpl

  private val modeSgdma = RegInit(true.B)

  when(!working && (start || axiStart)) {
    when(regMode === SgdmaMode.SGDMA.U) {
      working := true.B
      modeSgdma := true.B
      regCounter := 0.U
      sgdma.init()
    }.elsewhen(
      regMode === SgdmaMode.INIT_CONST.U || //
        regMode === SgdmaMode.INIT_LINEAR.U || //
        regMode === SgdmaMode.INIT_ZERO.U
    ) {
      working := true.B
      modeSgdma := false.B
      regCounter := 0.U
      init.init()
    }
  }

  m_axi_.ar.noenq()
  m_axi_.r.nodeq()

  m_axi_.aw.noenq()
  m_axi_.w.noenq()
  m_axi_.b.nodeq()

  when(working) {
    when(modeSgdma) {
      sgdma.work()
    }.otherwise {
      init.work()
    }
  }
}

case class SgdmaMultiConfig(
    val numMasters: Int,
    val sgdmaCfg: SgdmaConfig
) {
  require(numMasters >= 1)

  val axiDescCfg = axi4.Config(
    wAddr = sgdmaCfg.axiDescCfg.wAddr + log2Ceil(numMasters),
    wData = sgdmaCfg.axiDescCfg.wData,
    wId = 0
  )

  val axiCtrlCfg = axi4.Config(
    wAddr = sgdmaCfg.axiCtrlCfg.wAddr + log2Ceil(numMasters + 1),
    wData = sgdmaCfg.axiCtrlCfg.wData,
    lite = sgdmaCfg.axiCtrlCfg.lite
  )
}

class SgdmaMulti(val cfg: SgdmaMultiConfig) extends Module {
  import cfg._

  val s_axi_desc = IO(axi4.full.Slave(axiDescCfg))
  val s_axil_ctrl = IO(axi4.lite.Slave(axiCtrlCfg))
  val m_axiN = IO(Vec(numMasters, axi4.full.Master(sgdmaCfg.axiMasterCfg)))

  val start = IO(Input(Bool()))
  val busy = IO(Output(Bool()))

  private val regCounter = RegInit(0.U(64.W))

  private val dmaModules = Seq.fill(numMasters) {
    Module(new Sgdma(sgdmaCfg))
  }

  private val regBlock = new axi4.lite.components.RegisterBlock(
    wAddr = sgdmaCfg.axiCtrlCfg.wAddr,
    wData = sgdmaCfg.axiCtrlCfg.wData,
    wMask = sgdmaCfg.axiCtrlCfg.wAddr /* TODO: delete wMask later? */
  )

  private def interconnectControl(): Unit = prefix("interconnectControl") {
    import axi4.lite.components._

    val demux =
      Module(
        new Demux(
          DemuxConfig(axiCtrlCfg, numMasters + 1, (x: UInt) => (x >> sgdmaCfg.axiCtrlCfg.wAddr))
        )
      )

    s_axil_ctrl :=> demux.s_axil

    demux.m_axil(0) :=> regBlock.s_axil

    for (i <- (0 until numMasters)) {
      demux.m_axil(i + 1) :=> dmaModules(i).s_axil_ctrl
    }
  }
  interconnectControl()

  private def interconnectDesc(): Unit = prefix("interconnectDesc") {
    import axi4.full.components._

    val demux =
      Module(
        new Demux(
          DemuxConfig(axiDescCfg, numMasters, (x: UInt) => (x >> sgdmaCfg.axiDescCfg.wAddr))
        )
      )

    s_axi_desc :=> demux.s_axi

    for (i <- (0 until numMasters)) {
      demux.m_axi(i) :=> dmaModules(i).s_axi_desc
    }
  }
  interconnectDesc()

  private def initMasters(): Unit = {
    dmaModules.map { _.m_axi }.zip(m_axiN).foreach { //
      case (master, slave) => master :=> slave
    }
  }
  initMasters()

  private def initCtrl() = {
    object registerObj {
      regBlock.base(0)

      val REG_WORKING = regBlock.reg(busy, true, false, "REG_WORKING")
      val REG_COUNTER_LO = regBlock.reg(regCounter(31, 0), true, false, "REG_COUNTER_LO")
      val REG_COUNTER_HI = regBlock.reg(regCounter(63, 32), true, false, "REG_COUNTER_HI")
      val CMD_START = regBlock.reserve(4, "CMD_START")

      // regBlock.saveRegisterMap("output/", "SGDMA_multi")
    }

    import axi4.lite.components._

    val demux =
      Module(
        new Demux(
          DemuxConfig(axiCtrlCfg, numMasters + 1, (x: UInt) => (x >> sgdmaCfg.axiCtrlCfg.wAddr))
        )
      )

    s_axil_ctrl :=> demux.s_axil
    demux.m_axil(0) :=> regBlock.s_axil

    for (i <- (0 until numMasters)) {
      demux.m_axil(1 + i) :=> dmaModules(i).s_axil_ctrl
    }

    registerObj
  }
  val ctrlRegs = initCtrl()

  busy := VecInit(dmaModules.map(_.busy)).reduceTree(_ || _)
  dmaModules.foreach { _.start := start }

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
      dmaModules.foreach { _.start := true.B }
      regCounter := 0.U
    }

    regBlock.wrOk()
  }

  when(regBlock.rdReq) {
    regBlock.rdOk()
  }
}
