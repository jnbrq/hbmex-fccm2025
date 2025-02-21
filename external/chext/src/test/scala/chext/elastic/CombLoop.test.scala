package chext.elastic

import chisel3._
import chisel3.util._
import chiseltest._

import chext.elastic

object LoopySink {
  def apply[T <: Data](sink: ReadyValidIO[T]) = {
    dontTouch(sink)
    sink.ready := sink.valid
  }
}

class ArbiterCombLoopModule extends Module {
  val sources = IO(Vec(4, Source(Decoupled(UInt(32.W)))))

  private val sink = Wire(Decoupled(UInt(32.W)))
  private val selectSink = Wire(Decoupled(UInt(32.W)))

  elastic.Arbiter(
    sources,
    sink,
    Chooser.rr,
    Some(selectSink)
  )

  LoopySink(sink)
  LoopySink(selectSink)
}

class DistributorCombLoopModule extends Module {
  val source = IO(Source(Decoupled(UInt(32.W))))

  private val sinks = Wire(Vec(4, Decoupled(UInt(32.W))))
  private val selectSink = Wire(Decoupled(UInt(32.W)))

  elastic.Distributor(
    source,
    sinks,
    Chooser.rr,
    Some(selectSink)
  )

  sinks.foreach { LoopySink(_) }
  LoopySink(selectSink)
}

class MuxCombLoopModule extends Module {
  val sources = IO(Vec(4, Source(Decoupled(UInt(32.W)))))

  private val sink = Wire(Decoupled(UInt(32.W)))
  private val selectSource = Wire(Decoupled(UInt(32.W)))

  elastic.Mux(
    sources,
    sink,
    selectSource
  )

  LoopySink(sink)

  private val reg = RegInit(0.U(2.W))

  when(selectSource.fire) {
    reg := reg + 1.U
  }
  selectSource.valid := true.B
  selectSource.bits := reg
}

class DemuxCombLoopModule extends Module {
  val source = IO(Source(Decoupled(UInt(32.W))))

  private val sinks = Wire(Vec(4, Decoupled(UInt(32.W))))
  private val selectSource = Wire(Decoupled(UInt(32.W)))

  elastic.Demux(
    source,
    sinks,
    selectSource
  )

  sinks.foreach { LoopySink(_) }

  private val reg = RegInit(0.U(2.W))

  when(selectSource.fire) {
    reg := reg + 1.U
  }
  selectSource.valid := true.B
  selectSource.bits := reg
}

class JoinCombLoopModule extends Module {
  val sources = IO(Vec(4, Source(Decoupled(UInt(32.W)))))

  private val sink = Wire(Decoupled(Bool()))

  new Join(sink) {
    protected def onJoin: Unit = {
      sources.foreach { join(_) }
      out := true.B
    }
  }

  LoopySink(sink)
}

class ForkCombLoopModule extends Module {
  val source = IO(Source(Decoupled(UInt(32.W))))

  private val sinks = Wire(Vec(4, Decoupled(Bool())))

  new Fork(source) {
    protected def onFork: Unit = {
      import elastic.ConnectOp._

      sinks.foreach { (sink) => fork { true.B } :=> sink }
    }
  }

  sinks.foreach { LoopySink(_) }
}

class CombLoopTest extends chext.test.FreeSpec {

  /** the purpose of this test is to ensure that elastic modules do not introduce a combinational
    * path from ready to valid at sink(s). Such paths might results in combinational loops.
    */

  "elastic.CombLoopTest for ArbiterCombLoopModule" in
    test(new ArbiterCombLoopModule) { (dut) => {} }

  "elastic.CombLoopTest for DistributorCombLoopModule" in
    test(new DistributorCombLoopModule) { (dut) => {} }

  "elastic.CombLoopTest for MuxCombLoopModule" in
    test(new MuxCombLoopModule) { (dut) => {} }

  "elastic.CombLoopTest for DemuxCombLoopModule" in
    test(new DemuxCombLoopModule) { (dut) => {} }

  "elastic.CombLoopTest for JoinCombLoopModule" in
    test(new JoinCombLoopModule) { (dut) => {} }

  "elastic.CombLoopTest for ForkCombLoopModule" in
    test(new ForkCombLoopModule) { (dut) => {} }
}
