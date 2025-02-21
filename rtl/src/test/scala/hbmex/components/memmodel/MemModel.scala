package hbmex.components.memmodel

import chisel3._
import chisel3.util._
import chisel3.experimental.prefix

import chext.elastic
import chext.amba.axi4

import elastic.{Source, Sink, SourceBuffer}

import elastic.ConnectOp._
import chisel3.experimental.AffectsChiselPrefix

private class ElasticCounter(val maxValueExclusive: Int, val start: Int = 0) extends Module {
  require(start < maxValueExclusive)

  val width = log2Ceil(maxValueExclusive)

  val sink = IO(Sink(Irrevocable(UInt(width.W))))
  private val counter = RegInit(start.U(width.W))

  sink.enq(counter)

  when(sink.fire) {
    when(counter === (maxValueExclusive - 1).U) {
      counter := 0.U
    }.otherwise {
      counter := counter + 1.U
    }
  }
}

private object ElasticCounter {
  def apply(maxValueExclusive: Int = 0, start: Int = 0) = {
    val elasticCounter = Module(new ElasticCounter(maxValueExclusive, start))
    elasticCounter.sink
  }
}

/** Applies a certain fixed latency to the source.
  *
  * @param source
  * @param sink
  * @param latency
  */
private class Latency[T <: Data](source: ReadyValidIO[T], sink: ReadyValidIO[T], latency: Int)
    extends AffectsChiselPrefix {
  require(latency > 0)

  val counter = RegInit(0.U(log2Ceil(latency).W))

  new elastic.Arrival(source, sink) {
    protected def onArrival: Unit = {
      out := in

      when(counter === (latency - 1).U) {
        accept()
        counter := 0.U
      }.otherwise {
        noAccept()
        counter := counter + 1.U
      }
    }
  }
}

case class MemModelConfig(
    val numOutstandingRead: Int = 4,
    val latencyRead: Int = 32,
    val numOutstandingWrite: Int = 4,
    val latencyWrite: Int = 32
)

class MemModel(
    val axiCfg: axi4.Config,
    val memModelCfg: MemModelConfig
) extends Module {
  import memModelCfg._

  require(numOutstandingRead <= 64 && numOutstandingRead > 0)
  require(numOutstandingWrite <= 64 && numOutstandingWrite > 0)

  val s_axi = IO(axi4.full.Slave(axiCfg))

  private class ReadProcessor extends Module {
    val ar = IO(Source(Irrevocable(new axi4.full.ReadAddressChannel()(axiCfg))))
    val r = IO(Sink(Irrevocable(new axi4.full.ReadDataChannel()(axiCfg))))

    private val ar_0 = Wire(chiselTypeOf(ar))

    private val latency = new Latency(SourceBuffer(ar), ar_0, latencyRead)
    private val replicate = new elastic.Replicate(ar_0, r) {
      protected def onReplicate: Unit = {
        len := in.len +& 1.U

        out.id := in.id
        out.data := in.addr
        out.user := 0.U
        out.resp := axi4.ResponseFlag.OKAY

        out.last := last
      }
    }
  }

  private class WriteProcessor extends Module {
    val aw = IO(Source(Irrevocable(new axi4.full.WriteAddressChannel()(axiCfg))))
    val b = IO(Sink(Irrevocable(new axi4.full.WriteResponseChannel()(axiCfg))))

    private val aw_0 = Wire(chiselTypeOf(aw))

    private val latency = new Latency(SourceBuffer(aw), aw_0, latencyWrite)

    /** to simulate the transfer time */
    private val counter = RegInit(0.U(10.W))

    private val arrival = new elastic.Arrival(aw_0, b) {
      protected def onArrival: Unit = {
        out.id := in.id
        out.resp := axi4.ResponseFlag.OKAY
        out.user := 0.U

        when(counter === in.len) {
          accept()
          counter := 0.U
        }.otherwise {
          noAccept()
          counter := counter + 1.U
        }
      }
    }
  }

  private def implRead(): Unit = prefix("read") {
    val ar = s_axi.ar.asInstanceOf[IrrevocableIO[axi4.full.ReadAddressChannel]]
    val r = s_axi.r

    val demuxSel = RegInit(0.U(5.W))
    val muxSel = RegInit(0.U(5.W))

    val arX = Seq.fill(numOutstandingRead) { Wire(chiselTypeOf(ar)) }
    val rX = Seq.fill(numOutstandingRead) { Wire(chiselTypeOf(r)) }

    elastic.Demux(
      ar,
      arX,
      ElasticCounter(numOutstandingRead)
    )

    arX.zip(rX).zipWithIndex.foreach {
      case ((ar, r), idx) => {
        val readProcessor = Module(new ReadProcessor)
        ar :=> readProcessor.ar
        readProcessor.r :=> r
      }
    }

    elastic.Mux(
      rX,
      r,
      ElasticCounter(numOutstandingRead),
      (x: axi4.full.ReadDataChannel) => x.last
    )
  }
  implRead()

  private def implWrite(): Unit = prefix("write") {
    val aw = s_axi.aw
    val w = s_axi.w
    val b = s_axi.b

    val aw_0 = Wire(chiselTypeOf(aw))

    val bufLengthAW = 8

    val ctrAW = Module(new chext.util.Counter(bufLengthAW + 1))

    ctrAW.noDec()
    ctrAW.noInc()

    w.nodeq()
    when(ctrAW.notFull) {
      w.deq()

      when(w.fire && w.bits.last) {
        ctrAW.inc()
      }
    }

    new elastic.Arrival(aw, aw_0) {
      protected def onArrival: Unit = {
        out := in

        when(ctrAW.notZero) {
          accept()
          ctrAW.dec()
        }.otherwise {
          noAccept()
        }
      }
    }

    val awX = Seq.fill(numOutstandingWrite) { Wire(chiselTypeOf(aw)) }
    val bX = Seq.fill(numOutstandingWrite) { Wire(chiselTypeOf(b)) }

    elastic.Demux(
      aw_0,
      awX,
      ElasticCounter(numOutstandingWrite)
    )

    awX.zip(bX).zipWithIndex.foreach {
      case ((aw, b), idx) => {
        val writeProcessor = Module(new WriteProcessor)
        aw :=> writeProcessor.aw
        writeProcessor.b :=> b
      }
    }

    elastic.Mux(
      bX,
      b,
      ElasticCounter(numOutstandingWrite)
    )
  }
  implWrite()
}
