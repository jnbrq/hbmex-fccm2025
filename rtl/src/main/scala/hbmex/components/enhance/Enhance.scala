package hbmex.components.enhance

import chisel3._
import chisel3.util._

import chext.elastic
import elastic.ConnectOp._

import chext.amba.axi4
import axi4.Ops._

import axi4.full.components.{IdParallelizeNoReadBurst, IdParallelizeNoReadBurstConfig}

case class EnhanceConfig(
    val axiSlaveCfg: axi4.Config,
    val wSegmentOffset: Int,
    val log2numSegments: Int,
    val log2lenIdQueue: Int
) {
  val numSegments = 1 << log2numSegments

  // must be non-blocking demux
  val demuxCfg = DemuxConfig(axiSlaveCfg, log2numSegments, _ >> wSegmentOffset)
  val idSerializeCfg = IdSerializeConfig(demuxCfg.axiMasterCfg, 1 << log2lenIdQueue, 1 << log2lenIdQueue)
  val muxCfg = MuxConfig(idSerializeCfg.axiMasterCfg, log2numSegments)

  val axiMasterCfg = muxCfg.axiMasterCfg
}

class Enhance(cfg: EnhanceConfig) extends Module {
  import cfg._

  /** NOTE: this interface MUST HAVE unique IDs, otherwise the behavior is not defined */
  val s_axi = IO(axi4.full.Slave(axiSlaveCfg))
  val m_axi = IO(axi4.full.Master(axiMasterCfg))

  private val demux_ = Module(new Demux(demuxCfg))
  private val idSerialize_ = Seq.tabulate(numSegments) { //
    case (index) => Module(new IdSerialize(idSerializeCfg)).suggestName(f"idSerialize$index")
  }
  private val mux_ = Module(new Mux(muxCfg))

  val stages_ = new AxiFullStages

  stages_.addMasterInterface(s_axi)
  stages_.addSlaveInterface(m_axi)

  stages_.newStage("demux")
  stages_.addSlaveInterface(demux_.s_axi)
  stages_.addMasterInterfaces(demux_.m_axi)

  stages_.newStage("idSerialize")
  stages_.addSlaveInterfaces(idSerialize_.map { _.s_axi })
  stages_.addMasterInterfaces(idSerialize_.map { _.m_axi })

  stages_.newStage("mux")
  stages_.addSlaveInterfaces(mux_.s_axi)
  stages_.addMasterInterface(mux_.m_axi)

  stages_.connectAll()
}

object EmitEnhance extends App {
  val wAddr = 33
  val cfg = EnhanceConfig(
    axiSlaveCfg = axi4.Config(
      wId = 0,
      wAddr = wAddr,
      wData = 256,
      axi3Compat = true,
      hasQos = false,
      hasProt = false,
      hasCache = false,
      hasRegion = false,
      hasLock = false
    ),
    wSegmentOffset = 28,
    log2numSegments = 2,
    log2lenIdQueue = 6
  )

  emitVerilog(new Enhance(cfg))
}
