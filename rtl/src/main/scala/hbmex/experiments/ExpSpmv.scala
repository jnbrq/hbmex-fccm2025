package hbmex.experiments

import chisel3._
import chisel3.util._

import chext.elastic
import elastic.ConnectOp._

import chext.amba.axi4
import axi4.Ops._

import hbmex.components.spmv
import hbmex.components.stream

case class ExpSpmvConfig(val spmvCfg: spmv.SpmvConfig = spmv.SpmvConfig(64), val desiredName: String = "SpmvExpSpmv") {
  val memAdapterCfg = stream.MemAdapterConfig(spmv.Defs.wTime, spmv.Defs.wTask, 10)

  val responseBufferCfg = axi4.full.components.ResponseBufferConfig(
    spmvCfg.axiRandomCfg,
    512,
    2,
    writePassThrough = true
  )
}

class ExpSpmv(cfg: ExpSpmvConfig = ExpSpmvConfig()) extends Module {
  import cfg._
  override val desiredName: String = f"${cfg.desiredName}"

  private val spmv0 = Module(new spmv.Spmv(spmvCfg))
  private val memAdapter0 = Module(new stream.MemAdapter(memAdapterCfg))

  val S_AXI_CONTROL = IO(axi4.Slave(memAdapter0.s_axil.cfg))
  val M_AXI_RANDOM = IO(axi4.Master(spmvCfg.axiRandomCfg))
  val M_AXI_REGULAR = IO(axi4.Master(spmvCfg.axiRegularCfg))

  S_AXI_CONTROL.asLite :=> memAdapter0.s_axil

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

  private val responseBufferReadStreamValue = Module(
    new axi4.full.components.ResponseBuffer(responseBufferCfg)
  )
  spmv0.m_axi_random :=> axi4.full.MasterBuffer(responseBufferReadStreamValue.s_axi, axi4.BufferConfig.all(2))
  responseBufferReadStreamValue.m_axi :=> axi4.full.MasterBuffer(M_AXI_RANDOM.asFull, axi4.BufferConfig.all(2))

  spmv0.m_axi_regular :=> axi4.full.MasterBuffer(M_AXI_REGULAR.asFull, axi4.BufferConfig.all(2))
}

object EmitExpSpmv extends App {
  emitVerilog(new ExpSpmv(ExpSpmvConfig(spmv.SpmvConfig(64))))
}
