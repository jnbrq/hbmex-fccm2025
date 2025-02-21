package chext.elastic

import chisel3._
import chisel3.util._

import chiseltest._
import org.scalatest.freespec.AnyFreeSpec

import chext.elastic.ConnectOp._

class BuffersTestModule extends Module {
  val io = IO(new Bundle {
    val in = Source(Decoupled(UInt(8.W)))
    val out = Sink(Decoupled(UInt(8.W)))
  })

  val buf1_out = Wire(Decoupled(UInt(8.W)))
  val buf2_out = Wire(Decoupled(UInt(8.W)))
  val buf3_out = Wire(Decoupled(UInt(8.W)))

  SourceBuffer(io.in) :=> buf1_out
  SourceBuffer(buf1_out) :=> buf2_out
  SourceBuffer(buf2_out) :=> buf3_out
  SourceBuffer(buf3_out) :=> io.out
}

class BuffersTester extends AnyFreeSpec with ChiselScalatestTester {
  "elasticBuffersTest" in test(new BuffersTestModule).withAnnotations(Seq(WriteVcdAnnotation)) {
    dut =>
      dut.io.in.initSource()
      dut.io.out.initSink()

      fork {
        dut.io.in.enqueueSeq((0 until 100).map(_.U))
      }.fork {
        dut.io.out.expectDequeueSeq((0 until 100).map(_.U))
      }.join()
  }
}
