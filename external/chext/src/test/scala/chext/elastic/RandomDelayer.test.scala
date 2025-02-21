package chext.elastic

import chext.elastic

import chisel3._
import chisel3.util._
import chisel3.experimental._

import chiseltest._

import elastic.RandomDelayer

import org.scalatest.freespec.AnyFreeSpec

class RandomDelayerTest extends AnyFreeSpec with ChiselScalatestTester {
  "RandomDelayer should perform correctly" in {
    test(new RandomDelayer(UInt(32.W), lfsrBits = 4))
      .withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
        {
          dut.io.source.initSource()
          dut.io.sink.initSink()

          dut.io.source.enqueue(1.U)
          dut.io.sink.expectDequeue(1.U)

          dut.io.source.enqueue(2.U)
          dut.io.sink.expectDequeue(2.U)

          dut.io.source.enqueue(3.U)
          dut.io.sink.expectDequeue(3.U)

          dut.io.source.enqueue(4.U)
          dut.io.sink.expectDequeue(4.U)
        }
      }
  }
}
