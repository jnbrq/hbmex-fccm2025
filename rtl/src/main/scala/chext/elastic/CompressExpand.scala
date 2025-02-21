package chext.elastic

import chisel3._
import chisel3.util._

import chisel3.experimental.AffectsChiselPrefix

import ConnectOp._

/** Compresses zeros in a given string.
  *
  * 1111010001 --> 0, 0, 0, 0, 1, 3
  *
  * @param w
  * @param bufferLength
  * @param ones
  *   Replaces zeros/ones in the string.
  */
class Compress(val w: Int = 32, val bufferLength: Int = 2, val ones: Boolean = false) extends Module {
  require(w > 0)

  val source = IO(Source(Bool()))
  val sink = IO(Sink(UInt(w.W)))

  private val source_ = Wire(chiselTypeOf(source))

  if (ones) {
    val transform0 = new Transform(source, source_) {
      protected def onTransform: Unit = {
        out := !in
      }
    }
  } else
    source :=> source_

  private val rCounting = RegInit(false.B)
  private val rCount = RegInit(0.U(w.W))

  private val arrival0 = new ArrivalEx(source_, sink, bufferLength) {
    protected def onArrival: Unit = {
      when(rCounting) {
        when(in) {
          out := rCount

          rCounting := false.B
          rCount := 0.U

          accept()
        }.otherwise {
          rCount := rCount + 1.U

          consume()
        }
      }.otherwise {
        when(in) {
          out := 0.U

          accept()
        }.otherwise {
          rCounting := true.B
          rCount := 1.U

          consume()
        }
      }
    }
  }
}

/** Does the opposite of compress.
  *
  * @param w
  * @param bufferLength
  * @param ones
  */
class Expand(val w: Int = 32, val bufferLength: Int = 2, val ones: Boolean = false) extends Module {
  require(w > 0)

  val source = IO(Source(UInt(w.W)))
  val sink = IO(Sink(Bool()))

  private val sink_ = Wire(chiselTypeOf(sink))

  private val rCounting = RegInit(false.B)
  private val rCount = RegInit(0.U(w.W))

  private val arrival0 = new ArrivalEx(source, sink_, bufferLength) {
    protected def onArrival: Unit = {
      when(rCounting) {
        when(rCount === 0.U) {
          out := 1.B

          rCounting := false.B
          rCount := 0.U

          accept()
        }.otherwise {
          out := 0.B

          rCount := rCount - 1.U

          produce()
        }
      }.otherwise {
        when(in === 0.U) {
          out := 1.B

          accept()
        }.otherwise {
          out := 0.B

          rCounting := true.B
          rCount := in - 1.U

          produce()
        }
      }
    }
  }

  if (ones) {
    val transform0 = new Transform(sink_, sink) {
      protected def onTransform: Unit = {
        out := !in
      }
    }
  } else
    sink_ :=> sink
}

class CompressExpand(val w: Int = 32, val bufferLengthCompress: Int = 16, val bufferLengthExpand: Int = 2, val ones: Boolean = false) extends Module {
  val source = IO(Source(Bool()))
  val sink = IO(Sink(Bool()))

  private val compress = Module(new Compress(w, bufferLengthCompress, ones))
  private val expand = Module(new Expand(w, bufferLengthExpand, ones))

  source :=> compress.source
  compress.sink :=> expand.source
  expand.sink :=> sink
}
