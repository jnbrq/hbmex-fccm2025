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

case class SpmvExp1Config(val desiredName: String = "SpmvExp1") {
  val spmvCfg: spmv.SpmvConfig = spmv.SpmvConfig(64, hbmCompat = false)

  val axiControlCfg = axi4.Config(wAddr = 12, wData = 32, lite = true)

  val controlDemuxCfg = axi4.lite.components.DemuxConfig(
    axiControlCfg,
    3,
    _ >> 10
  )

  val memAdapterCfg = stream.MemAdapterConfig(spmv.Defs.wTime, spmv.Defs.wTask, 10)

  val responseBufferCfg = axi4.full.components.ResponseBufferConfig(
    spmvCfg.axiRandomCfg,
    512,
    2,
    writePassThrough = true
  )

  val stripeTransformations = Seq(
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

  val stripeCfg0 =
    stripe.StripeConfig(
      1,
      spmvCfg.axiRandomCfg.copy(wAddr = 34),
      stripeTransformations
    )

  val stripeCfg1 =
    stripe.StripeConfig(
      1,
      spmvCfg.axiRegularCfg.copy(wAddr = 34),
      stripeTransformations
    )
}

class SpmvExp1(cfg: SpmvExp1Config = SpmvExp1Config()) extends Module {
  import cfg._
  override val desiredName: String = f"${cfg.desiredName}"

  private val spmv0 = Module(new spmv.Spmv(spmvCfg))
  private val memAdapter0 = Module(new stream.MemAdapter(memAdapterCfg))
  private val stripe0 = Module(new stripe.Stripe(stripeCfg0))
  private val stripe1 = Module(new stripe.Stripe(stripeCfg1))

  val S_AXI_CONTROL = IO(axi4.Slave(axiControlCfg))

  val S_AXI_STRIPED = IO(axi4.Slave(stripeCfg1.axiCfg))
  val M_AXI_STRIPED = IO(axi4.Master(stripeCfg1.axiCfg))

  val M_AXI_RANDOM = IO(axi4.Master(spmvCfg.axiRandomCfg))
  val M_AXI_REGULAR = IO(axi4.Master(spmvCfg.axiRegularCfg))

  private val controlDemux = Module(new axi4.lite.components.Demux(controlDemuxCfg))

  S_AXI_CONTROL.asLite :=> controlDemux.s_axil

  controlDemux.m_axil(0) :=> memAdapter0.s_axil
  controlDemux.m_axil(1) :=> stripe0.S_AXI_CONTROL.asLite
  controlDemux.m_axil(2) :=> stripe1.S_AXI_CONTROL.asLite

  S_AXI_STRIPED :=> stripe1.S_AXI(0)
  stripe1.M_AXI(0) :=> M_AXI_STRIPED

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

  private val responseBuffer = Module(
    new axi4.full.components.ResponseBuffer(responseBufferCfg)
  )

  spmv0.m_axi_random :=> axi4.full.MasterBuffer(stripe0.S_AXI(0).asFull, axi4.BufferConfig.all(2))
  stripe0.M_AXI(0) :=> axi4.full.MasterBuffer(responseBuffer.s_axi, axi4.BufferConfig.all(2))
  responseBuffer.m_axi :=> axi4.full.MasterBuffer(M_AXI_RANDOM.asFull, axi4.BufferConfig.all(2))

  spmv0.m_axi_regular :=> axi4.full.MasterBuffer(M_AXI_REGULAR.asFull, axi4.BufferConfig.all(2))
}

object EmitSpmvExp1 extends App {
  emitVerilog(new SpmvExp1(SpmvExp1Config()))
}
