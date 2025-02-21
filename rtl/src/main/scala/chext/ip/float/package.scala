package chext.ip

import chisel3._
import chisel3.util._

package object float {
  private val debug = false

  implicit class fixedPointHelpers(fx: SInt) {
    def to_floating_point(gen_fp: FloatingPoint): FloatingPoint = {
      val result = Wire(gen_fp)
      val fixed_point_width = fx.getWidth
      val mantissa_width = gen_fp.mantissa_width

      // by extending the mantissa, we automatically get rid of the preceding 1
      // which is not part of the floating point representation
      val extended_mantissa = Wire(UInt((fixed_point_width + 1).W))

      val sign = fx(fixed_point_width - 1)

      when(sign === 0.B) {
        extended_mantissa := Cat(0.B, fx.asUInt)
      }.otherwise {
        extended_mantissa := Cat(0.B, (-fx).asUInt)
      }

      val shift = PriorityEncoder(Reverse(extended_mantissa))
      val shifted = (extended_mantissa << shift)

      if (fixed_point_width >= mantissa_width) {
        result.mantissa := shifted(
          fixed_point_width - 1,
          (fixed_point_width - 1) - mantissa_width + 1
        )
      } else {
        result.mantissa := Cat(
          shifted(fixed_point_width - 1, 0),
          0.U((mantissa_width - fixed_point_width).W)
        )
      }

      result.sign := sign
      when(fx === 0.S) {
        result.exponent := 0.U
      }.otherwise {
        result.exponent := fixed_point_width.U +& result.exponent_offset.U -& shift
      }

      if (debug) {
        dontTouch(extended_mantissa.suggestName("_D_extended_mantissa"))
        dontTouch(shift.suggestName("_D_shift"))
        dontTouch(shifted.suggestName("_D_shifted"))
        dontTouch(
          shifted(fixed_point_width - 1, 0).suggestName("_D_shifted_slice")
        )
        dontTouch(result.mantissa.suggestName("_D_result_mantissa"))
        println(s"padding = ${mantissa_width - fixed_point_width}")
      }

      result
    }
  }

  implicit class fixedPointHelpersU(fx: UInt) {
    def to_floating_point(gen_fp: FloatingPoint): FloatingPoint = {
      val result = Wire(gen_fp)
      val fixed_point_width = fx.getWidth
      val mantissa_width = gen_fp.mantissa_width
      val extended_mantissa = Cat(0.B, fx)

      val shift = PriorityEncoder(Reverse(extended_mantissa))
      val shifted = (extended_mantissa << shift)

      if (fixed_point_width >= mantissa_width) {
        result.mantissa := shifted(
          fixed_point_width - 1,
          (fixed_point_width - 1) - mantissa_width + 1
        )
      } else {
        result.mantissa := Cat(
          shifted(fixed_point_width - 1, 0),
          0.U((mantissa_width - fixed_point_width).W)
        )
      }

      result.sign := 0.B
      when(fx === 0.U) {
        result.exponent := 0.U
      }.otherwise {
        result.exponent := fixed_point_width.U +& result.exponent_offset.U -& shift
      }
      result
    }
  }

  implicit class floatingPointHelpers(fp: FloatingPoint) {
    def to_unsigned_fixed_point(gen_fx: UInt): UInt = {
      val result = Wire(gen_fx)
      val fixed_point_width = gen_fx.getWidth
      val mantissa_width = fp.mantissa_width
      val extended_mantissa = Cat(1.B, fp.mantissa)
      val breakpt = fp.exponent_offset + fixed_point_width - 1

      val a = Wire(gen_fx)

      if (fixed_point_width > mantissa_width) {
        val constant_0 = fixed_point_width - mantissa_width - 1
        if (constant_0 > 0)
          a := Cat(1.B, fp.mantissa, 0.U(constant_0.W))
        else
          a := Cat(1.B, fp.mantissa)
      } else {
        a := Cat(
          1.B,
          fp.mantissa(
            mantissa_width - 1,
            (mantissa_width - 1) - (fixed_point_width - 1) + 1
          )
        )
      }

      when(fp.exponent === 0.U) {
        result := 0.U
      }.elsewhen(fp.exponent > breakpt.U) {
        result := (-1).S(fixed_point_width.W).asUInt
      }.otherwise /* floating_point.exponent <= breakpt.U */ {
        result := a >> (breakpt.U -% fp.exponent)
      }

      result
    }

    def to_fixed_point(gen_fx: SInt): SInt = {
      val result = Wire(gen_fx)
      val fixed_point_width = gen_fx.getWidth

      val a = Wire(gen_fx)
      val a_neg = Wire(gen_fx)

      a := to_unsigned_fixed_point(UInt(fixed_point_width.W)).asSInt
      a_neg := -a

      when(~fp.sign) {
        when(a(fixed_point_width - 1)) {
          // overflow
          result := Cat(0.B, (-1).S((fixed_point_width - 1).W)).asSInt
        }.otherwise {
          result := a
        }
      }.otherwise {
        when(~a_neg(fixed_point_width - 1)) {
          // overflow
          result := Cat(1.B, (0).S((fixed_point_width - 1).W)).asSInt
        }.otherwise {
          result := a_neg
        }
      }

      result
    }
  }

  implicit class DoubleHelpers(d: Double) {
    def to_floating_point_hw(fp: FloatingPoint) = {
      TestFloatingPoint.from_double(d)(fp).to_floating_point_hw
    }
  }
}
