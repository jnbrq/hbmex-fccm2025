package chext.elastic

import chisel3._
import chisel3.util._

// TODO: Shall we disallow connections between Decoupled and Irrevocable?

object connect {
  def apply[T <: Data](source: ReadyValidIO[T], sink: ReadyValidIO[T]) = {
    source.ready := sink.ready
    sink.valid := source.valid
    sink.bits := source.bits
  }
}

object ConnectOp {
  implicit class elastic_connect_op[T <: Data](source: ReadyValidIO[T]) {
    def :=>(sink: ReadyValidIO[T]): Unit = {
      connect(source, sink)
    }
  }
}
