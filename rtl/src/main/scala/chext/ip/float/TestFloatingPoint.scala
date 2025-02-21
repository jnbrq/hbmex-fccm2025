package chext.ip.float

import chisel3._
import chiseltest._
import scala.util.Random

case class TestFloatingPoint(var sign: Boolean, var exponent: Int, var mantissa: BigInt)(implicit fp: FloatingPoint) {
  def to_double: Double = {
    // let's generate a double by hand
    var result = 0.toLong
    var bit_sign = (if (sign) 1.toLong else 0.toLong) << 63
    // rearrange the offsets
    var bit_exponent = (exponent.toLong + ((2048 - (1 << fp.exponent_width)) >> 1)) << 52
    // rearrange the mantissas
    var bit_mantissa = mantissa.toLong << (52 - fp.mantissa_width)
    // println((bit_sign | bit_exponent | bit_mantissa).toBinaryString.reverse.padTo(64, '0').reverse)
    java.lang.Double.longBitsToDouble(bit_sign | bit_exponent | bit_mantissa)
  }

  def from_double(d: Double) = {
    val sign_mask = 1.toLong
    val exponent_mask = (1.toLong << 11) - 1
    val mantissa_mask = (1.toLong << 52) - 1
    val double_bits = java.lang.Double.doubleToLongBits(d)
    sign = ((double_bits >> 63) & sign_mask) > 0
    exponent = ((double_bits >> 52) & exponent_mask).toInt - ((2048 - (1 << fp.exponent_width)) >> 1)
    mantissa = (double_bits & mantissa_mask) >> (52 - fp.mantissa_width)
    if (exponent < 0) {
      // in case the number turns out to be very small
      exponent = 0
      mantissa = 0
      sign = false
    }
  }

  def from_fixed_point(exponent: Int, mantissa: Long) = {
    if (mantissa == 0) {
      this.sign = false
      this.exponent = 0
      this.mantissa = 0
    } else {
      // shift the mantissa to left until its most significant bit (63rd)
      // is 1
      val msb_mask = 1L << 63
      var shifted_mantissa = math.abs(mantissa)
      var shift_amount: Long = 0
      while ((shifted_mantissa & msb_mask) == 0) {
        shifted_mantissa = shifted_mantissa << 1
        shift_amount = shift_amount + 1
      }

      // strip the initial one
      // now, shifted_mantissa is basically the "decimal" part of the normalized number
      shifted_mantissa = shifted_mantissa & ~msb_mask
      // remark: if we do another shift left, it turns out to be the sign bit
      // which causes problems when shifting left later

      // now, let's rewind it to assign the mantissa
      this.mantissa = shifted_mantissa >> (63 - fp.mantissa_width)

      // assign the exponent
      this.exponent = (exponent - shift_amount + 63 + fp.exponent_offset).toInt

      // and finally the sign bit
      this.sign = mantissa < 0
    }
  }

  def to_floating_point_hw: FloatingPoint = {
    val res = Wire(fp.cloneType)
    res.sign := sign.B
    res.mantissa := mantissa.U
    res.exponent := exponent.U
    res
  }

  def poke(fp: FloatingPoint): Unit = {
    fp.sign.poke(if (sign) 1 else 0)
    fp.exponent.poke(exponent)
    fp.mantissa.poke(mantissa)
  }

  def peek(fp: FloatingPoint): Unit = {
    sign = fp.sign.peekInt() == 1
    exponent = fp.exponent.peekInt().toInt
    mantissa = fp.mantissa.peekInt()
  }
}

object TestFloatingPoint {
  def random(implicit fp: FloatingPoint, random: Random): TestFloatingPoint = {
    TestFloatingPoint(
      BigInt(1, random) == 0,
      BigInt(fp.exponent_width, random).toInt,
      BigInt(fp.mantissa_width, random)
    )
  }

  def from_double(d: Double)(implicit fp: FloatingPoint): TestFloatingPoint = {
    val result = new TestFloatingPoint(false, 0, 0)
    result.from_double(d)
    result
  }

  def from_fixed_point(exponent: Int, mantissa: Long)(implicit
      fp: FloatingPoint
  ): TestFloatingPoint = {
    val result = new TestFloatingPoint(false, 0, 0)
    result.from_fixed_point(exponent, mantissa)
    result
  }

  def peek(signal: FloatingPoint): TestFloatingPoint = {
    val result = new TestFloatingPoint(false, 0, 0)(signal)
    result.peek(signal)
    result
  }
}
