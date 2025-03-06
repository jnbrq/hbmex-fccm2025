package hbmex.experiments

import chisel3._
import chisel3.util._

import chext.elastic
import elastic.ConnectOp._

import chext.amba.axi4
import axi4.Ops._

import hbmex.components.spmv
import hbmex.components.stream
import hbmex.components.stripe
import hbmex.components.id_parallelize
import hbmex.components.enhance

case class SpmvExp3Config(val desiredName: String = "SpmvExp3") {
  // No need for the response buffer because the ID parallelize module already has a buffer
  val spmvCfg: spmv.SpmvConfig = spmv.SpmvConfig(64, hbmCompat = true, useResponseBufferRandom = false)

  val axiControlCfg = axi4.Config(wAddr = 11, wData = 32, lite = true)

  val controlDemuxCfg = axi4.lite.components.DemuxConfig(
    axiControlCfg,
    2,
    _ >> 10
  )

  val memAdapterCfg = stream.MemAdapterConfig(spmv.Defs.wTime, spmv.Defs.wTask, 10)

  // BEGIN: HBMex Components Config

  val stripeCfg = {
    val transformations = Seq(
      Seq(33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
      Seq(33, 32, 31, 30, 14, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 29, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
      Seq(33, 32, 31, 15, 14, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 30, 29, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
      Seq(33, 32, 16, 15, 14, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 31, 30, 29, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
      Seq(33, 17, 16, 15, 14, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 32, 31, 30, 29, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
      Seq(18, 17, 16, 15, 14, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 33, 32, 31, 30, 29, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,

      // for failsafe
      Seq(33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
      Seq(33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse
    )

    stripe.StripeConfig(
      2,
      spmvCfg.axiRandomMasterCfg.copy(wAddr = 34),
      transformations
    )
  }

  val idParallizeCfg = id_parallelize.IdParallelizeNoReadBurstConfig(
    axiSlaveCfg = spmvCfg.axiRandomMasterCfg,
    wIdMaster = 8 /* 2 **8 = 256 is the buffer size, number of outstanding requests */
  )

  val enhanceCfg = enhance.EnhanceConfig(
    axiSlaveCfg = idParallizeCfg.axiMasterCfg,
    wSegmentOffset = 29,
    log2numSegments = 3,
    log2lenIdQueue = 6
  )

  // END: HBMex Components
}

class SpmvExp3(cfg: SpmvExp3Config = SpmvExp3Config()) extends Module {
  import cfg._
  override val desiredName: String = f"${cfg.desiredName}"

  private val spmv0 = Module(new spmv.Spmv(spmvCfg))
  private val memAdapter0 = Module(new stream.MemAdapter(memAdapterCfg))

  // BEGIN: HBMex Components

  private val stripe0 = Module(new stripe.Stripe(stripeCfg))
  private val idParallize0 = Module(new id_parallelize.IdParallelizeNoReadBurst(idParallizeCfg))
  private val enhance0 = Module(new enhance.Enhance(enhanceCfg))

  // END: HBMex Components

  val S_AXI_CONTROL = IO(axi4.Slave(axiControlCfg))

  val S_AXI_STRIPED = IO(axi4.Slave(stripeCfg.axiCfg))
  val M_AXI_STRIPED = IO(axi4.Master(stripeCfg.axiCfg))

  val M_AXI_RANDOM = IO(axi4.Master(enhanceCfg.axiMasterCfg))
  val M_AXI_REGULAR = IO(axi4.Master(spmvCfg.axiRegularMasterCfg))

  private val controlDemux = Module(new axi4.lite.components.Demux(controlDemuxCfg))

  S_AXI_CONTROL.asLite :=> controlDemux.s_axil

  controlDemux.m_axil(0) :=> memAdapter0.s_axil
  controlDemux.m_axil(1) :=> stripe0.S_AXI_CONTROL.asLite

  S_AXI_STRIPED :=> stripe0.S_AXI(1)
  stripe0.M_AXI(1) :=> M_AXI_STRIPED

  new elastic.Transform(elastic.SourceBuffer(memAdapter0.sink, 4), spmv0.sourceTask) {
    protected def onTransform: Unit = {
      out := in.asTypeOf(out)
    }
  }

  new elastic.Transform(spmv0.sinkDone, elastic.SinkBuffer(memAdapter0.source, 4)) {
    protected def onTransform: Unit = {
      out := in.asUInt
    }
  }

  spmv0.m_axi_random :=> axi4.full.MasterBuffer(stripe0.S_AXI(0).asFull, axi4.BufferConfig.all(2))
  stripe0.M_AXI(0).asFull :=> axi4.full.MasterBuffer(idParallize0.s_axi, axi4.BufferConfig.all(2))
  idParallize0.m_axi :=> axi4.full.MasterBuffer(enhance0.s_axi, axi4.BufferConfig.all(2))
  enhance0.m_axi :=> axi4.full.MasterBuffer(M_AXI_RANDOM.asFull, axi4.BufferConfig.all(2))

  spmv0.m_axi_regular :=> axi4.full.MasterBuffer(M_AXI_REGULAR.asFull, axi4.BufferConfig.all(2))
}

object EmitSpmvExp3 extends App {
  emitVerilog(new SpmvExp3(SpmvExp3Config()))
}
