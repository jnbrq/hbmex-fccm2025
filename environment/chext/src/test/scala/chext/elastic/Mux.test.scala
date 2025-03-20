package chext.elastic

import chext.elastic

import chisel3._
import chisel3.util._
import chisel3.experimental.BundleLiterals._

import chiseltest._

import org.scalatest.freespec.AnyFreeSpec

import scala.collection.mutable.ArrayBuffer

class MuxSpec extends AnyFreeSpec with ChiselScalatestTester {
  class DataLast extends Bundle {
    val data = UInt(32.W)
    val last = Bool()
  }

  val genDataLast = new DataLast
  def dataLast(data: BigInt, last: Boolean) =
    genDataLast.Lit(_.data -> data.U, _.last -> last.B)

  "elastic.Mux Basic functionality" in {
    test(
      new elastic.Mux(UInt(32.W), 4)
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      {
        // Initialize the IO
        dut.io.sources.foreach { _.initSource() }
        dut.io.select.initSource()
        dut.io.sink.initSink()

        // Start testing
        fork {
          dut.io.sources(0).enqueue(0xa0.U)
        }.fork {
          dut.io.sources(1).enqueue(0xb0.U)
        }.fork {
          dut.io.sources(2).enqueue(0xc0.U)
        }.fork {
          dut.io.sources(3).enqueue(0xd0.U)
        }.fork {
          dut.io.select.enqueue(0x00.U)
          dut.io.select.enqueue(0x01.U)
          dut.io.select.enqueue(0x02.U)
          dut.io.select.enqueue(0x03.U)
        }.fork {
          dut.io.sink.expectDequeue(0xa0.U)
          dut.io.sink.expectDequeue(0xb0.U)
          dut.io.sink.expectDequeue(0xc0.U)
          dut.io.sink.expectDequeue(0xd0.U)
        }.join()
      }
    }
  }

  "elastic.Mux Basic functionality (randomized)" in {
    val rand = scala.util.Random
    val MAX_CHANNEL = 8
    val TEST_LENGTH = 100

    val nChannels = 2 + rand.nextInt(MAX_CHANNEL)
    val selValues = Array.fill(TEST_LENGTH) { rand.nextInt(nChannels) }
    val msgValues = Array.fill(TEST_LENGTH) { math.abs(rand.nextInt()).U }

    val chnData = Array.fill(nChannels) { ArrayBuffer[UInt]() }

    for (i <- 0 until TEST_LENGTH) {
      val index = selValues(i)
      val data = msgValues(i)
      chnData(index).addOne(data)
    }

    test(
      new elastic.Mux(UInt(32.W), nChannels)
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      {
        // Initialize the IO
        dut.io.sources.foreach { _.initSource() }
        dut.io.select.initSource()
        dut.io.sink.initSink()

        // Start testing
        var f = fork {}

        for (i <- 0 until nChannels) {
          f = f.fork {
            chnData(i).foreach { x =>
              {
                dut.io.sources(i).enqueue(x)
                dut.clock.step(rand.nextInt(4) + 1)
              }
            }
          }
        }

        f.fork {
          selValues.foreach { x =>
            {
              dut.io.select.enqueue(x.U)
              dut.clock.step(rand.nextInt(4) + 1)
            }
          }
        }.fork {
          msgValues.foreach { x =>
            dut.io.sink.expectDequeue(x)
          }
        }.join()
      }
    }
  }

  "elastic.Mux Burst functionality" in {
    val gen = new DataLast

    test(
      new elastic.Mux(gen, 4, (x: DataLast) => x.last)
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      {
        // Initialize the IO
        dut.io.sources.foreach { _.initSource() }
        dut.io.select.initSource()
        dut.io.sink.initSink()

        // Start testing
        fork {
          dut.io.sources(0).enqueue(dataLast(0xa0, false))
          dut.io.sources(0).enqueue(dataLast(0xa1, false))
          dut.io.sources(0).enqueue(dataLast(0xa2, true))
          dut.clock.step(2)
          dut.io.sources(0).enqueue(dataLast(0xa3, false))
          dut.io.sources(0).enqueue(dataLast(0xa4, false))
          dut.io.sources(0).enqueue(dataLast(0xa5, true))
          dut.clock.step(2)
        }.fork {
          dut.io.sources(1).enqueue(dataLast(0xb0, false))
          dut.io.sources(1).enqueue(dataLast(0xb1, false))
          dut.io.sources(1).enqueue(dataLast(0xb2, true))
          dut.clock.step(2)
        }.fork {
          dut.io.sources(2).enqueue(dataLast(0xc0, false))
          dut.io.sources(2).enqueue(dataLast(0xc1, false))
          dut.io.sources(2).enqueue(dataLast(0xc2, true))
          dut.clock.step(2)
        }.fork {
          dut.io.sources(3).enqueue(dataLast(0xd0, false))
          dut.io.sources(3).enqueue(dataLast(0xd1, false))
          dut.io.sources(3).enqueue(dataLast(0xd2, true))
          dut.clock.step(2)
        }.fork {
          dut.io.select.enqueue(0x00.U)
          dut.io.select.enqueue(0x01.U)
          dut.io.select.enqueue(0x02.U)
          dut.io.select.enqueue(0x03.U)
          dut.io.select.enqueue(0x00.U)
        }.fork {
          dut.io.sink.expectDequeue(dataLast(0xa0, false))
          dut.io.sink.expectDequeue(dataLast(0xa1, false))
          dut.io.sink.expectDequeue(dataLast(0xa2, true))

          dut.io.sink.expectDequeue(dataLast(0xb0, false))
          dut.io.sink.expectDequeue(dataLast(0xb1, false))
          dut.io.sink.expectDequeue(dataLast(0xb2, true))

          dut.io.sink.expectDequeue(dataLast(0xc0, false))
          dut.io.sink.expectDequeue(dataLast(0xc1, false))
          dut.io.sink.expectDequeue(dataLast(0xc2, true))

          dut.io.sink.expectDequeue(dataLast(0xd0, false))
          dut.io.sink.expectDequeue(dataLast(0xd1, false))
          dut.io.sink.expectDequeue(dataLast(0xd2, true))

          dut.io.sink.expectDequeue(dataLast(0xa3, false))
          dut.io.sink.expectDequeue(dataLast(0xa4, false))
          dut.io.sink.expectDequeue(dataLast(0xa5, true))
        }.join()

      }
    }
  }

  "elastic.Mux Burst functionality (randomized)" in {
    val gen = new DataLast
    val rand = scala.util.Random
    val MAX_CHANNEL = 8
    val MAX_BURST_LENGTH = 8
    val MAX_WAIT = 4
    val TEST_LENGTH = 100

    val nChannels = 2 + rand.nextInt(MAX_CHANNEL)
    val selValues = Array.fill(TEST_LENGTH) { rand.nextInt(nChannels) }
    val chnData = Array.fill(nChannels) { ArrayBuffer[ArrayBuffer[DataLast]]() }

    val msgValues = Array.fill(TEST_LENGTH) { ArrayBuffer[DataLast]() }

    msgValues.foreach { x =>
      {
        val n = 1 + rand.nextInt(MAX_BURST_LENGTH)
        for (i <- 0 until n) {
          x.addOne(dataLast(math.abs(rand.nextInt()), i == n - 1))
        }
      }
    }

    for (i <- 0 until TEST_LENGTH) {
      val index = selValues(i)
      val n = 1 + rand.nextInt(MAX_BURST_LENGTH)
      val data = msgValues(i)
      chnData(index).addOne(data)
    }

    test(
      new elastic.Mux(gen, nChannels, (x: DataLast) => x.last)
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      {
        // Initialize the IO
        dut.io.sources.foreach { _.initSource() }
        dut.io.select.initSource()
        dut.io.sink.initSink()

        // Start testing
        var f = fork {}

        for (i <- 0 until nChannels) {
          f = f.fork {
            chnData(i).foreach(pck =>
              pck.foreach { x =>
                {
                  dut.io.sources(i).enqueue(x)
                  dut.clock.step(rand.nextInt(MAX_WAIT) + 1)
                }
              }
            )
          }
        }

        f.fork {
          selValues.foreach { x =>
            {
              dut.io.select.enqueue(x.U)
              dut.clock.step(rand.nextInt(4) + 1)
            }
          }
        }.fork {
          msgValues.foreach { pck =>
            pck.foreach(x => dut.io.sink.expectDequeue(x))
          }
        }.join()

      }
    }
  }
}
