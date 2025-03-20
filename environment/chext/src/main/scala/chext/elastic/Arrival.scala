package chext.elastic

import chisel3._
import chisel3.util._
import chisel3.experimental._

/** @note
  *   Never declare registers inside `onAccept`!
  *
  * @param source
  * @param sink
  */
abstract class Arrival[Tin <: Data, T <: Data](
    source: ReadyValidIO[Tin],
    sink: ReadyValidIO[T],
    flow: Boolean = false,
    pipe: Boolean = false,
    depth: Int = 2
) extends AffectsChiselPrefix {
  private val sinkBuffered_ = SinkBuffer.decoupled(sink, n = depth, flow = flow, pipe = pipe)
  protected val in = source.bits
  protected val out = sinkBuffered_.bits

  out := DontCare

  /** Accepts the current packet, optionally transforming it.
    *
    * @param t
    */
  protected def accept(): Unit = {
    source.ready := true.B
    sinkBuffered_.valid := true.B
  }

  /** Does not accept the packet yet. The packet stay as long as not dropped.
    */
  protected def noAccept(): Unit = {
    source.ready := false.B
    sinkBuffered_.valid := false.B
  }

  /** Drops the current packet.
    */
  protected def drop(): Unit = {
    source.ready := true.B
    sinkBuffered_.valid := false.B
  }

  /** Consumes the current packet from the source.
    */
  protected def consume(): Unit = {
    source.ready := true.B
  }

  /** Produces a new packet to the sink.
    *
    * @param t
    */
  protected def produce(): Unit = {
    sinkBuffered_.valid := true.B
  }

  /** Called when a packet might be accepted.
    */
  protected def onArrival: Unit

  noAccept()
  when(sinkBuffered_.ready && source.valid) {
    onArrival
  }
}
