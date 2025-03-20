package chext.util

import chisel3._
import chisel3.util.ReadyValidIO

class BackpressureMonitor[T <: Data](rv: ReadyValidIO[T], name: String)
    extends chisel3.experimental.AffectsChiselPrefix {
  val counter = RegInit(0.U(32.W))
  counter := counter + 1.U

  val doPrint = RegInit(true.B)

  when(rv.valid && !rv.ready) {
    when(doPrint) {
      printf("[BackpressureMonitor] counter = %d: Backpressure on " + name + "\n", counter)
      doPrint := false.B
    }
  }.otherwise {
    doPrint := true.B
  }
}
