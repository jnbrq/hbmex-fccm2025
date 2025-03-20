package chext.elastic

import chext.elastic

import chisel3._
import chisel3.util._
import chisel3.experimental.BundleLiterals._

import chiseltest._

import org.scalatest.freespec.AnyFreeSpec

class BasicArbiterSpec extends AnyFreeSpec with ChiselScalatestTester {
  class DataLast extends Bundle {
    val data = UInt(32.W)
    val last = Bool()
  }

  val genDataLast = new DataLast
  def dataLast(data: BigInt, last: Boolean) =
    genDataLast.Lit(_.data -> data.U, _.last -> last.B)

  "elastic.BasicArbiter Basic functionality" in {
    test(
      new elastic.BasicArbiter(UInt(32.W), 4, chext.elastic.Chooser.priority)
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      {
        dut.io.sources.foreach { _.initSource() }
        dut.io.sink.initSink()
        dut.io.select.initSink()

        fork {
          dut.io.sources(0).enqueue(0xa0.U)
          dut.io.sources(0).enqueue(0xa1.U)
          dut.io.sources(0).enqueue(0xa2.U)
        }.fork {
          dut.io.sources(1).enqueue(0xb0.U)
          dut.io.sources(1).enqueue(0xb1.U)
          dut.io.sources(1).enqueue(0xb2.U)
        }.fork {
          dut.io.sources(2).enqueue(0xc0.U)
          dut.io.sources(2).enqueue(0xc1.U)
          dut.io.sources(2).enqueue(0xc2.U)
        }.fork {
          dut.io.sources(3).enqueue(0xd0.U)
          dut.io.sources(3).enqueue(0xd1.U)
          dut.io.sources(3).enqueue(0xd2.U)
        }.fork {
          dut.io.sink.expectDequeue(0xa0.U)
          dut.io.sink.expectDequeue(0xa1.U)
          dut.io.sink.expectDequeue(0xa2.U)
          dut.io.sink.expectDequeue(0xb0.U)
          dut.io.sink.expectDequeue(0xb1.U)
          dut.io.sink.expectDequeue(0xb2.U)
          dut.io.sink.expectDequeue(0xc0.U)
          dut.io.sink.expectDequeue(0xc1.U)
          dut.io.sink.expectDequeue(0xc2.U)
          dut.io.sink.expectDequeue(0xd0.U)
          dut.io.sink.expectDequeue(0xd1.U)
          dut.io.sink.expectDequeue(0xd2.U)
        }.fork {
          dut.io.select.expectDequeue(0.U)
          dut.io.select.expectDequeue(0.U)
          dut.io.select.expectDequeue(0.U)
          dut.io.select.expectDequeue(1.U)
          dut.io.select.expectDequeue(1.U)
          dut.io.select.expectDequeue(1.U)
          dut.io.select.expectDequeue(2.U)
          dut.io.select.expectDequeue(2.U)
          dut.io.select.expectDequeue(2.U)
          dut.io.select.expectDequeue(3.U)
          dut.io.select.expectDequeue(3.U)
          dut.io.select.expectDequeue(3.U)
        }.join()
      }
    }
  }

  "elastic.BasicArbiter Round Robin" in {
    test(
      new elastic.BasicArbiter(UInt(32.W), 4, chext.elastic.Chooser.rr)
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      {
        dut.io.sources.foreach { _.initSource() }
        dut.io.sink.initSink()
        dut.io.select.initSink()

        fork {
          dut.io.sources(0).enqueue(0xa0.U)
          dut.io.sources(0).enqueue(0xa1.U)
        }.fork {
          dut.io.sources(1).enqueue(0xb0.U)
          dut.io.sources(1).enqueue(0xb1.U)
        }.fork {
          dut.io.sources(2).enqueue(0xc0.U)
          dut.io.sources(2).enqueue(0xc1.U)
        }.fork {
          dut.io.sources(3).enqueue(0xd0.U)
          dut.io.sources(3).enqueue(0xd1.U)
        }.fork {
          dut.io.sink.expectDequeue(0xb0.U)
          dut.io.sink.expectDequeue(0xc0.U)
          dut.io.sink.expectDequeue(0xd0.U)
          dut.io.sink.expectDequeue(0xa0.U)
          dut.io.sink.expectDequeue(0xb1.U)
          dut.io.sink.expectDequeue(0xc1.U)
          dut.io.sink.expectDequeue(0xd1.U)
          dut.io.sink.expectDequeue(0xa1.U)
        }.fork {
          dut.io.select.expectDequeue(1.U)
          dut.io.select.expectDequeue(2.U)
          dut.io.select.expectDequeue(3.U)
          dut.io.select.expectDequeue(0.U)
          dut.io.select.expectDequeue(1.U)
          dut.io.select.expectDequeue(2.U)
          dut.io.select.expectDequeue(3.U)
          dut.io.select.expectDequeue(0.U)
        }.join()

        dut.clock.step(3)

        fork {
          dut.io.sources(1).enqueue(0xb2.U)
        }.fork {
          dut.io.sources(3).enqueue(0xd2.U)
        }.fork {
          dut.io.sink.expectDequeue(0xb2.U)
          dut.io.sink.expectDequeue(0xd2.U)
        }.fork {
          dut.io.select.expectDequeue(1.U)
          dut.io.select.expectDequeue(3.U)
        }.join()
      }
    }
  }
}

class ArbiterSpec extends AnyFreeSpec with ChiselScalatestTester {
  class DataLast extends Bundle {
    val data = UInt(32.W)
    val last = Bool()
  }

  val genDataLast = new DataLast
  def dataLast(data: BigInt, last: Boolean) =
    genDataLast.Lit(_.data -> data.U, _.last -> last.B)

  "elastic.Arbiter Basic functionality" in {
    test(
      new elastic.Arbiter(UInt(32.W), 4, chext.elastic.Chooser.priority)
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      {
        dut.io.sources.foreach { _.initSource() }
        dut.io.sink.initSink()
        dut.io.select.initSink()

        fork {
          dut.io.sources(0).enqueue(0xa0.U)
          dut.io.sources(0).enqueue(0xa1.U)
          dut.io.sources(0).enqueue(0xa2.U)
        }.fork {
          dut.io.sources(1).enqueue(0xb0.U)
          dut.io.sources(1).enqueue(0xb1.U)
          dut.io.sources(1).enqueue(0xb2.U)
        }.fork {
          dut.io.sources(2).enqueue(0xc0.U)
          dut.io.sources(2).enqueue(0xc1.U)
          dut.io.sources(2).enqueue(0xc2.U)
        }.fork {
          dut.io.sources(3).enqueue(0xd0.U)
          dut.io.sources(3).enqueue(0xd1.U)
          dut.io.sources(3).enqueue(0xd2.U)
        }.fork {
          dut.io.sink.expectDequeue(0xa0.U)
          dut.io.sink.expectDequeue(0xa1.U)
          dut.io.sink.expectDequeue(0xa2.U)
          dut.io.sink.expectDequeue(0xb0.U)
          dut.io.sink.expectDequeue(0xb1.U)
          dut.io.sink.expectDequeue(0xb2.U)
          dut.io.sink.expectDequeue(0xc0.U)
          dut.io.sink.expectDequeue(0xc1.U)
          dut.io.sink.expectDequeue(0xc2.U)
          dut.io.sink.expectDequeue(0xd0.U)
          dut.io.sink.expectDequeue(0xd1.U)
          dut.io.sink.expectDequeue(0xd2.U)
        }.fork {
          dut.io.select.expectDequeue(0.U)
          dut.io.select.expectDequeue(0.U)
          dut.io.select.expectDequeue(0.U)
          dut.io.select.expectDequeue(1.U)
          dut.io.select.expectDequeue(1.U)
          dut.io.select.expectDequeue(1.U)
          dut.io.select.expectDequeue(2.U)
          dut.io.select.expectDequeue(2.U)
          dut.io.select.expectDequeue(2.U)
          dut.io.select.expectDequeue(3.U)
          dut.io.select.expectDequeue(3.U)
          dut.io.select.expectDequeue(3.U)
        }.join()
      }
    }
  }

  "elastic.Arbiter Burst functionality" in {
    test(
      new elastic.Arbiter(
        genDataLast,
        4,
        chext.elastic.Chooser.priority,
        (x: DataLast) => x.last
      )
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      {
        dut.io.sources.foreach { _.initSource() }
        dut.io.sink.initSink()
        dut.io.select.initSink()

        fork {
          dut.io.sources(0).enqueue(dataLast(0xa0, false))
          dut.io.sources(0).enqueue(dataLast(0xa1, false))
          dut.io.sources(0).enqueue(dataLast(0xa2, true))
          dut.clock.step(2)
          dut.io.sources(0).enqueue(dataLast(0xa7, false))
          dut.io.sources(0).enqueue(dataLast(0xa8, false))
          dut.io.sources(0).enqueue(dataLast(0xa9, true))
        }.fork {
          dut.io.sources(1).enqueue(dataLast(0xb0, false))
          dut.io.sources(1).enqueue(dataLast(0xb1, false))
          dut.io.sources(1).enqueue(dataLast(0xb2, true))
        }.fork {
          dut.io.sources(2).enqueue(dataLast(0xc0, false))
          dut.io.sources(2).enqueue(dataLast(0xc1, false))
          dut.io.sources(2).enqueue(dataLast(0xc2, true))
        }.fork {
          dut.io.sources(3).enqueue(dataLast(0xd0, false))
          dut.io.sources(3).enqueue(dataLast(0xd1, false))
          dut.io.sources(3).enqueue(dataLast(0xd2, true))
        }.fork {
          dut.io.sink.expectDequeue(dataLast(0xa0, false))
          dut.io.sink.expectDequeue(dataLast(0xa1, false))
          dut.io.sink.expectDequeue(dataLast(0xa2, true))
          dut.io.sink.expectDequeue(dataLast(0xb0, false))
          dut.io.sink.expectDequeue(dataLast(0xb1, false))
          dut.io.sink.expectDequeue(dataLast(0xb2, true))
          dut.io.sink.expectDequeue(dataLast(0xa7, false))
          dut.io.sink.expectDequeue(dataLast(0xa8, false))
          dut.io.sink.expectDequeue(dataLast(0xa9, true))
          dut.io.sink.expectDequeue(dataLast(0xc0, false))
          dut.io.sink.expectDequeue(dataLast(0xc1, false))
          dut.io.sink.expectDequeue(dataLast(0xc2, true))
          dut.io.sink.expectDequeue(dataLast(0xd0, false))
          dut.io.sink.expectDequeue(dataLast(0xd1, false))
          dut.io.sink.expectDequeue(dataLast(0xd2, true))
        }.fork {
          dut.io.select.expectDequeue(0.U)
          dut.io.select.expectDequeue(1.U)
          dut.io.select.expectDequeue(0.U)
          dut.io.select.expectDequeue(2.U)
          dut.io.select.expectDequeue(3.U)
        }.join()
      }
    }
  }

  "elastic.Arbiter Round Robin" in {
    test(
      new elastic.Arbiter(UInt(32.W), 4, chext.elastic.Chooser.rr)
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      {
        dut.io.sources.foreach { _.initSource() }
        dut.io.sink.initSink()
        dut.io.select.initSink()

        fork {
          dut.io.sources(0).enqueue(0xa0.U)
          dut.io.sources(0).enqueue(0xa1.U)
        }.fork {
          dut.io.sources(1).enqueue(0xb0.U)
          dut.io.sources(1).enqueue(0xb1.U)
        }.fork {
          dut.io.sources(2).enqueue(0xc0.U)
          dut.io.sources(2).enqueue(0xc1.U)
        }.fork {
          dut.io.sources(3).enqueue(0xd0.U)
          dut.io.sources(3).enqueue(0xd1.U)
        }.fork {
          dut.io.sink.expectDequeue(0xb0.U)
          dut.io.sink.expectDequeue(0xc0.U)
          dut.io.sink.expectDequeue(0xd0.U)
          dut.io.sink.expectDequeue(0xa0.U)
          dut.io.sink.expectDequeue(0xb1.U)
          dut.io.sink.expectDequeue(0xc1.U)
          dut.io.sink.expectDequeue(0xd1.U)
          dut.io.sink.expectDequeue(0xa1.U)
        }.fork {
          dut.io.select.expectDequeue(1.U)
          dut.io.select.expectDequeue(2.U)
          dut.io.select.expectDequeue(3.U)
          dut.io.select.expectDequeue(0.U)
          dut.io.select.expectDequeue(1.U)
          dut.io.select.expectDequeue(2.U)
          dut.io.select.expectDequeue(3.U)
          dut.io.select.expectDequeue(0.U)
        }.join()

        dut.clock.step(3)

        fork {
          dut.io.sources(1).enqueue(0xb2.U)
        }.fork {
          dut.io.sources(3).enqueue(0xd2.U)
        }.fork {
          dut.io.sink.expectDequeue(0xb2.U)
          dut.io.sink.expectDequeue(0xd2.U)
        }.fork {
          dut.io.select.expectDequeue(1.U)
          dut.io.select.expectDequeue(3.U)
        }.join()
      }
    }
  }

  "elastic.Arbiter Round Robin with Burst" in {
    test(
      new elastic.Arbiter(
        genDataLast,
        4,
        chext.elastic.Chooser.rr,
        (x: DataLast) => x.last
      )
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      {
        dut.io.sources.foreach { _.initSource() }
        dut.io.sink.initSink()
        dut.io.select.initSink()

        fork {
          dut.io.sources(0).enqueue(dataLast(0xa0, false))
          dut.io.sources(0).enqueue(dataLast(0xa1, true))
        }.fork {
          dut.io.sources(1).enqueue(dataLast(0xb0, false))
          dut.io.sources(1).enqueue(dataLast(0xb1, true))
        }.fork {
          dut.io.sources(2).enqueue(dataLast(0xc0, true))
          dut.io.sources(2).enqueue(dataLast(0xc1, true))
        }.fork {
          dut.io.sources(3).enqueue(dataLast(0xd0, true))
          dut.io.sources(3).enqueue(dataLast(0xd1, true))
        }.fork {
          dut.io.sink.expectDequeue(dataLast(0xb0, false))
          dut.io.sink.expectDequeue(dataLast(0xb1, true))
          dut.io.sink.expectDequeue(dataLast(0xc0, true))
          dut.io.sink.expectDequeue(dataLast(0xd0, true))
          dut.io.sink.expectDequeue(dataLast(0xa0, false))
          dut.io.sink.expectDequeue(dataLast(0xa1, true))
          dut.io.sink.expectDequeue(dataLast(0xc1, true))
          dut.io.sink.expectDequeue(dataLast(0xd1, true))
        }.fork {
          dut.io.select.expectDequeue(1.U)
          dut.io.select.expectDequeue(2.U)
          dut.io.select.expectDequeue(3.U)
          dut.io.select.expectDequeue(0.U)
          dut.io.select.expectDequeue(2.U)
          dut.io.select.expectDequeue(3.U)
        }.join()
      }
    }
  }
}
