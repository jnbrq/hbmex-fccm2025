package chext.elastic

import chext.elastic

import chisel3._
import chisel3.util._
import chisel3.experimental.BundleLiterals._

import chiseltest._

import elastic._
import elastic.ConnectOp._
import elastic.test.PacketOps._

class TestPE extends Module {
  val genDataLast = new DataLast

  val io = IO(new Bundle {
    val source = Flipped(Decoupled(genDataLast))
    val sink = Decoupled(genDataLast)
  })

  val isBurst = RegInit(false.B)
  val accumulated = RegInit(0.U(32.W))

  new Arrival(io.source, io.sink) {
    protected def onArrival: Unit = {
      consume() /* consume the source packet */

      when(in.last) {
        when(isBurst) {
          out.data := accumulated + in.data
          out.last := true.B
        }.otherwise {
          out.data := in.data
          out.last := true.B
        }

        produce() /* send the sink packet */
        isBurst := false.B
      }.otherwise {
        when(isBurst) {
          accumulated := accumulated + in.data
        }.otherwise {
          accumulated := in.data
        }

        isBurst := true.B
      }
    }
  }

  /** Note to myself: do not declare any stateful elements, like registers, inside new Arrival {
    * ... } block. These elements confuse Chisel.
    */
}

class DistributorTestDevice(
    val n: Int,
    val chooserFn: Chooser.ChooserFn
) extends Module {
  val genDataLast = new DataLast

  val io = IO(new Bundle {
    val source = Flipped(Decoupled(genDataLast))
    val sink = Decoupled(genDataLast)
  })

  val Distributor =
    Module(new Distributor(genDataLast, n, chooserFn, (x: DataLast) => x.last))

  val processElements = Array.fill(n) { Module(new TestPE) }

  val sinkMux = Module(
    new elastic.Mux(genDataLast, n, (x: DataLast) => x.last)
  )

  Distributor.io.sinks.zip(processElements).foreach {
    case (x, y) => {
      x :=> SinkBuffer(y.io.source)
    }
  }

  sinkMux.io.sources.zip(processElements).foreach {
    case (x, y) => {
      SourceBuffer(y.io.sink) :=> x
    }
  }

  elastic.SourceBuffer.irrevocable(
    Distributor.io.select,
    8
  ) :=> sinkMux.io.select

  io.source :=> Distributor.io.source
  sinkMux.io.sink :=> io.sink
}

object DistributorTestDevice extends App {
  import chisel3.stage._

  emitVerilog(
    new DistributorTestDevice(2, chext.elastic.Chooser.priority),
    Array("--target-dir", "sink/")
  )
}

class DistributorSpec extends chext.test.FreeSpec {
  enableVcd()

  val genDataLast = new DataLast
  def dataLast(data: BigInt, last: Boolean) =
    genDataLast.Lit(_.data -> data.U, _.last -> last.B)

  "elastic.Distributor Basic functionality" in {
    test(
      new elastic.Distributor(UInt(32.W), 4, chext.elastic.Chooser.rr)
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      {
        dut.io.source.initSource()
        dut.io.sinks.foreach { _.initSink() }
        dut.io.select.initSink()

        dut.io.sinks.foreach { _.ready.poke(true) }
        dut.io.select.ready.poke(true)

        fork {
          dut.io.source.enqueue(0xb0.U)
          dut.io.source.enqueue(0xc0.U)
          dut.io.source.enqueue(0xd0.U)
          dut.io.source.enqueue(0xa0.U)
          dut.io.source.enqueue(0xb1.U)
          dut.io.source.enqueue(0xc1.U)
          dut.io.source.enqueue(0xd1.U)
          dut.io.source.enqueue(0xa1.U)
          dut.io.source.enqueue(0xb2.U)
          dut.io.source.enqueue(0xc2.U)
          dut.io.source.enqueue(0xd2.U)
          dut.io.source.enqueue(0xa2.U)
        }.fork {
          dut.io.select.expectDequeue(0x01.U)
          dut.io.select.expectDequeue(0x02.U)
          dut.io.select.expectDequeue(0x03.U)
          dut.io.select.expectDequeue(0x00.U)
          dut.io.select.expectDequeue(0x01.U)
          dut.io.select.expectDequeue(0x02.U)
          dut.io.select.expectDequeue(0x03.U)
          dut.io.select.expectDequeue(0x00.U)
          dut.io.select.expectDequeue(0x01.U)
          dut.io.select.expectDequeue(0x02.U)
          dut.io.select.expectDequeue(0x03.U)
          dut.io.select.expectDequeue(0x00.U)
        }.fork {
          dut.io.sinks(0).expectDequeue(0xa0.U)
          dut.io.sinks(0).expectDequeue(0xa1.U)
          dut.io.sinks(0).expectDequeue(0xa2.U)
        }.fork {
          dut.io.sinks(1).expectDequeue(0xb0.U)
          dut.io.sinks(1).expectDequeue(0xb1.U)
          dut.io.sinks(1).expectDequeue(0xb2.U)
        }.fork {
          dut.io.sinks(2).expectDequeue(0xc0.U)
          dut.io.sinks(2).expectDequeue(0xc1.U)
          dut.io.sinks(2).expectDequeue(0xc2.U)
        }.fork {
          dut.io.sinks(3).expectDequeue(0xd0.U)
          dut.io.sinks(3).expectDequeue(0xd1.U)
          dut.io.sinks(3).expectDequeue(0xd2.U)
        }.join()
      }
    }

  }

  "elastic.Distributor Burst functionality" in {
    test(
      new elastic.Distributor(
        genDataLast,
        4,
        chext.elastic.Chooser.rr,
        (x: DataLast) => x.last
      )
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      {
        dut.io.source.initSource()
        dut.io.sinks.foreach { _.initSink() }
        dut.io.select.initSink()

        dut.io.sinks.foreach { _.ready.poke(true) }

        fork {
          dut.io.source.enqueue(dataLast(0xa0, false))
          dut.io.source.enqueue(dataLast(0xa1, true))
          dut.io.source.enqueue(dataLast(0xa2, false))
          dut.io.source.enqueue(dataLast(0xa3, true))

          dut.io.source.enqueue(dataLast(0xb0, false))
          dut.io.source.enqueue(dataLast(0xb1, true))
          dut.io.source.enqueue(dataLast(0xb2, false))
          dut.io.source.enqueue(dataLast(0xb3, true))

          dut.io.source.enqueue(dataLast(0xc0, false))
          dut.io.source.enqueue(dataLast(0xc1, true))
          dut.io.source.enqueue(dataLast(0xc2, false))
          dut.io.source.enqueue(dataLast(0xc3, true))

          dut.io.source.enqueue(dataLast(0xd0, false))
          dut.io.source.enqueue(dataLast(0xd1, true))
          dut.io.source.enqueue(dataLast(0xd2, false))
          dut.io.source.enqueue(dataLast(0xd3, true))

        }.fork {
          dut.io.select.expectDequeue(0x01.U)
          dut.io.select.expectDequeue(0x02.U)
          dut.io.select.expectDequeue(0x03.U)
          dut.io.select.expectDequeue(0x00.U)

          dut.io.select.expectDequeue(0x01.U)
          dut.io.select.expectDequeue(0x02.U)
          dut.io.select.expectDequeue(0x03.U)
          dut.io.select.expectDequeue(0x00.U)

        }.fork {
          dut.io.sinks(1).expectDequeue(dataLast(0xa0, false))
          dut.io.sinks(1).expectDequeue(dataLast(0xa1, true))

          dut.io.sinks(1).expectDequeue(dataLast(0xc0, false))
          dut.io.sinks(1).expectDequeue(dataLast(0xc1, true))

        }.fork {
          dut.io.sinks(2).expectDequeue(dataLast(0xa2, false))
          dut.io.sinks(2).expectDequeue(dataLast(0xa3, true))

          dut.io.sinks(2).expectDequeue(dataLast(0xc2, false))
          dut.io.sinks(2).expectDequeue(dataLast(0xc3, true))

        }.fork {
          dut.io.sinks(3).expectDequeue(dataLast(0xb0, false))
          dut.io.sinks(3).expectDequeue(dataLast(0xb1, true))

          dut.io.sinks(3).expectDequeue(dataLast(0xd0, false))
          dut.io.sinks(3).expectDequeue(dataLast(0xd1, true))

        }.fork {
          dut.io.sinks(0).expectDequeue(dataLast(0xb2, false))
          dut.io.sinks(0).expectDequeue(dataLast(0xb3, true))

          dut.io.sinks(0).expectDequeue(dataLast(0xd2, false))
          dut.io.sinks(0).expectDequeue(dataLast(0xd3, true))

        }.join()
      }
    }
  }

  "elastic.Distributor Burst functionality (randomized)" in {
    val gen = new DataLast
    val rand = scala.util.Random
    val MAX_CHANNEL = 8
    val MAX_BURST_LENGTH = 8
    val MAX_WAIT = 4
    val TEST_LENGTH = 100

    val nChannels = 2 + rand.nextInt(MAX_CHANNEL)
    val msgValues = Array.fill(TEST_LENGTH) {
      scala.collection.mutable.ArrayBuffer[DataLast]()
    }

    msgValues.foreach { x =>
      {
        val n = 1 + rand.nextInt(MAX_BURST_LENGTH)
        for (i <- 0 until n) {
          x.addOne(dataLast(math.abs(rand.nextInt(4)), i == n - 1))
        }
      }
    }

    val expValues = scala.collection.mutable.ArrayBuffer[Int]()

    msgValues.foreach { x =>
      {
        var sum = 0
        x.foreach(y => sum += y.data.litValue.toInt)
        expValues.addOne(sum)
      }
    }

    test(
      new DistributorTestDevice(nChannels, chext.elastic.Chooser.priority)
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      {
        // Initialize the IO
        dut.io.source.initSource()
        dut.io.sink.initSink()

        // Start testing
        fork {
          msgValues.foreach(msg => {
            msg.foreach(x => {
              dut.io.source.enqueue(x)
              dut.clock.step(1 + rand.nextInt(MAX_WAIT))
            })
          })
        }.fork {
          expValues.foreach(x => {
            dut.io.sink.expectDequeue(dataLast(x, true))
          })
        }.join()
      }
    }
  }
}
