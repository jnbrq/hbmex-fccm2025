package hbmex.components.stream

import chisel3._
import chisel3.util._

import chext.elastic
import elastic.ConnectOp._

import chext.amba.axi4
import axi4.Ops._

import chext.util.BitOps._

case class MemAdapterConfig(val sourceWidth: Int, val sinkWidth: Int, val wAddr: Int = 10) {
  require(sourceWidth <= (1 << (wAddr - 2 + 3)))
  require(sinkWidth <= (1 << (wAddr - 2 + 3)))

  // maybe not necessary?
  require(sourceWidth > 0)
  require(sinkWidth > 0)

  val wData = 32
  val axiSlaveCfg = axi4.Config(wAddr = wAddr, wData = wData, lite = true)

  val sourceWordCount = (sourceWidth + (wData - 1)) >> log2Ceil(wData)
  val sinkWordCount = (sinkWidth + (wData - 1)) >> log2Ceil(wData)
}

class MemAdapter(cfg: MemAdapterConfig) extends Module {
  import cfg._

  val s_axil = IO(axi4.lite.Slave(axiSlaveCfg))
  val source = IO(elastic.Source(UInt(sourceWidth.W)))
  val sink = IO(elastic.Sink(UInt(sinkWidth.W)))

  private val regBlock = new axi4.lite.components.RegisterBlock(wAddr, wData, wAddr)

  s_axil :=> regBlock.s_axil

  private val rSourceDeqOne = RegInit(false.B)
  private val rSourceDataVector = source.bits.asTypeOf(Vec(sourceWordCount, UInt(32.W)))

  private val rSinkEnqOne = RegInit(false.B)

  private val rSinkDataVector = Seq.fill(sinkWordCount) { RegInit(0.U(32.W)) }
  private val rSinkData = VecInit(rSinkDataVector).asUInt

  regBlock.base(0)

  regBlock.reg(source.valid, true, false, "SOURCE_VALID")
  regBlock.reg(rSourceDeqOne, true, true, "SOURCE_DEQ_ONE")

  regBlock.reg(sink.ready, true, false, "SINK_READY")
  regBlock.reg(rSinkEnqOne, true, true, "SINK_ENQ_ONE")

  regBlock.base(2 << (wAddr - 2))
  rSourceDataVector.zipWithIndex.foreach {
    case (rSourceDataElem, idx) => {
      regBlock.reg(rSourceDataElem, true, false, f"SOURCE_DATA_$idx")
    }
  }

  regBlock.base(3 << (wAddr - 2))
  rSinkDataVector.zipWithIndex.foreach {
    case (rSinkDataElem, idx) => {
      regBlock.reg(rSinkDataElem, true, true, f"SINK_DATA_$idx")
    }
  }

  source.nodeq()
  when(rSourceDeqOne) {
    source.deq()

    when(source.fire) {
      rSourceDeqOne := false.B
    }
  }

  sink.noenq()
  when(rSinkEnqOne) {
    sink.enq(rSinkData)

    when(sink.fire) {
      rSinkEnqOne := false.B
    }
  }

  when(regBlock.rdReq) {
    regBlock.rdOk()
  }

  when(regBlock.wrReq) {
    regBlock.wrOk()
  }
}

object EmitMemAdapter extends App {
  emitVerilog(new MemAdapter(MemAdapterConfig(64, 64, 10)))
}
