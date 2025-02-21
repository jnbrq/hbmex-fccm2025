package chext.ip.float

import chisel3._

/** Floating point type.
  *
  * @param exponent_width
  *   Exponent width.
  * @param mantissa_width
  *   Mantissa width (excluding the sign bit).
  */
case class FloatingPoint(val exponent_width: Int, val mantissa_width: Int) extends Bundle {
  val sign = Bool()
  val exponent = UInt(exponent_width.W)
  val mantissa = UInt(mantissa_width.W)

  val exponent_offset = (BigInt(1) << (exponent_width - 1)) - 1

  def zero: FloatingPoint = {
    0.U.asTypeOf(this)
  }

  /** @return
    *   A string representation of the bundle.
    */
  override def toString(): String = s"fpe${exponent_width}m${mantissa_width}"
}

object FloatingPoint {
  def ieee_fp16 = FloatingPoint(5, 10)
  def ieee_fp32 = FloatingPoint(8, 23)
  def ieee_fp64 = FloatingPoint(11, 52)
  def fp18 = FloatingPoint(10, 7)
  def bfloat16 = FloatingPoint(8, 7)
}
