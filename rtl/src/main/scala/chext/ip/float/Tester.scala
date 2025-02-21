package chext.ip.float

import chisel3._
import chisel3.util._

import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

trait Delay {
  val delay: Int
}

trait UnaryOp[T <: Data] {
  def in: T
  def out: T
}

trait BinaryOp[T <: Data] {
  def in_a: T
  def in_b: T
  def out: T
}

class FloatingPointBinaryOpTester[
    Dut <: Module with BinaryOp[FloatingPoint] with Delay
](
    dut: Dut,
    val expected_op: (Double, Double) => Double
) extends AnyFlatSpec {
  @annotation.nowarn // Implicit definition should have explicit type
  implicit val fp = dut.in_a

  val exp_offset = ((1 << fp.exponent_width) >> 1) - 1

  def test(
      fp1: TestFloatingPoint,
      fp2: TestFloatingPoint
  ): TestFloatingPoint = {
    fp1.poke(dut.in_a)
    fp2.poke(dut.in_b)

    dut.clock.step(math.max(dut.delay, 1))

    val res = TestFloatingPoint.peek(dut.out)

    val fp1d = fp1.to_double
    val fp2d = fp2.to_double
    val resd = res.to_double
    val expected_value = expected_op(fp1d, fp2d)
    val ratio = resd / (expected_value)
    val success = ratio.isNaN() || ratio < 1.1 && ratio > 0.9

    println(f"in_a = $fp1d, in_b = $fp2d, out = $resd, expected = $expected_value, in_a* = $fp1, in_b* = $fp2, out* = $res, ratio = $ratio")
    assert(success, "ratio is not in the acceptable range!")

    res
  }
}

class FloatingPointUnaryOpTester[
    Dut <: Module with UnaryOp[FloatingPoint] with Delay
](
    dut: Dut,
    val expected_op: Double => Double
) extends AnyFlatSpec {
  @annotation.nowarn // Implicit definition should have explicit type
  implicit val fp = dut.in

  val exp_offset = ((1 << fp.exponent_width) >> 1) - 1

  def test(
      fp1: TestFloatingPoint
  ): TestFloatingPoint = {
    fp1.poke(dut.in)

    dut.clock.step(math.max(dut.delay, 1))

    val res = TestFloatingPoint.peek(dut.out)

    val fp1d = fp1.to_double
    val resd = res.to_double
    val expected_value = expected_op(fp1d)
    val ratio = resd / expected_value
    val success = ratio.isNaN || (ratio < 1.1 && ratio > 0.9)

    println(f"in_a = $fp1d, out = $resd, expected = $expected_value, in_a* = $fp1, out* = $res, ratio = $ratio")
    assert(success, "ratio is not in the acceptable range!")

    res
  }
}
