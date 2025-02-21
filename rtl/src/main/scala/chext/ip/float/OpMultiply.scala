package chext.ip.float

import chisel3._
import chisel3.util._
import os.copy.over

class OpMultiply(val gen_fp: FloatingPoint, val combinational: Boolean = false)
    extends Module //
    with BinaryOp[FloatingPoint] //
    with Delay {
  override val delay = if (combinational) 0 else 3

  val io = IO(new Bundle {
    val in_a = Input(gen_fp)
    val in_b = Input(gen_fp)

    val out = Output(gen_fp)
  })

  val in_a = io.in_a
  val in_b = io.in_b
  val out = io.out

  val in_a__ = in_a.asUInt
  val in_b__ = in_b.asUInt
  val out__ = out.asUInt

  dontTouch(in_a__)
  dontTouch(in_b__)
  dontTouch(out__)

  if (combinational) {
    val module = Module(new MulFp_Combinational(gen_fp))

    module.io.in_a := io.in_a
    module.io.in_b := io.in_b
    io.out := module.io.out
  } else {
    val module = Module(new MulFp_Pipelined(gen_fp))

    module.io.in_a := io.in_a
    module.io.in_b := io.in_b
    io.out := module.io.out
  }
}

object EmitOpMultiply extends App {
  emitVerilog(new OpMultiply(FloatingPoint.ieee_fp32))
}
