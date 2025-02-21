package chext.elastic

import chisel3._
import chisel3.util._
import chisel3.experimental.requireIsHardware

object Constant {
  def apply[T <: Data](t: T): IrrevocableIO[T] = {
    requireIsHardware(t)
    val constant = Wire(Irrevocable(chiselTypeOf(t)))

    constant.bits := t
    constant.valid := true.B

    constant
  }
}
