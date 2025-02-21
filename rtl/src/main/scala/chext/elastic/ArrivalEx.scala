package chext.elastic

import chisel3._
import chisel3.util._
import chisel3.experimental.AffectsChiselPrefix

/** Just like arrival, but with configurable buffer length.
  *
  * @param source
  * @param sink
  * @param bufferLength
  */
abstract class ArrivalEx[Tin <: Data, T <: Data](
    source: ReadyValidIO[Tin],
    sink: ReadyValidIO[T],
    bufferLength: Int
) extends AffectsChiselPrefix {
  require(bufferLength >= 2)

  private val sinkBuffered_ = SinkBuffer.decoupled(sink, bufferLength)
  protected val in = source.bits
  protected val out = sinkBuffered_.bits

  out := DontCare

  protected def accept(): Unit = {
    source.ready := true.B
    sinkBuffered_.valid := true.B
  }

  protected def noAccept(): Unit = {
    source.ready := false.B
    sinkBuffered_.valid := false.B
  }

  protected def drop(): Unit = {
    source.ready := true.B
    sinkBuffered_.valid := false.B
  }

  protected def consume(): Unit = {
    source.ready := true.B
  }

  protected def produce(): Unit = {
    sinkBuffered_.valid := true.B
  }

  protected def onArrival: Unit

  noAccept()
  when(sinkBuffered_.ready && source.valid) {
    onArrival
  }
}
