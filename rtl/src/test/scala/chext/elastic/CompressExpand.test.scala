package chext.elastic

import chisel3._
import chisel3.util._

import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class CompressExpandTester extends AnyFlatSpec with ChiselScalatestTester {
  "CompressExpand" should "work" in {
    test(new CompressExpand).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      {
        dut.sink.initSink()
        dut.source.initSource()

        val testVectors = Seq(
          Seq(0, 0, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 1),
          Seq(1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1)
        )

        fork {
          testVectors.foreach { testVector => { dut.source.enqueueSeq(testVector.map { _.B }) } }
        }.fork {
          testVectors.foreach { testVector => { dut.sink.expectDequeueSeq(testVector.map { _.B }) } }
        }.join()
      }
    }
  }
}
