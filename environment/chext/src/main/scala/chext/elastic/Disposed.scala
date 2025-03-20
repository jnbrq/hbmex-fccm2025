package chext.elastic

import chisel3._
import chisel3.util._

object Disposed {
  /** Disposes the sink of the given ready/valid interface.
    *
    * @param rv
    */
  def apply[T <: Data](rv: ReadyValidIO[T]) = {
    rv.ready := true.B
  }
}
