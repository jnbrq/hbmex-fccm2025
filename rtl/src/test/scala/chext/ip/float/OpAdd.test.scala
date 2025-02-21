package chext.ip.float

import chisel3._
import chisel3.util._

import scala.util.Random

class AddUnitBasicTester(dut: OpAdd) extends FloatingPointBinaryOpTester(dut, _ + _) {
  require(fp.mantissa_width >= 3)
  require(fp.exponent_width >= 3)

  test(
    TestFloatingPoint(false, 0 + exp_offset, 1 << (fp.mantissa_width - 3)),
    TestFloatingPoint(false, 0 + exp_offset, 4 << (fp.mantissa_width - 3))
  )
  test(
    TestFloatingPoint(false, 0 + exp_offset, BigInt(1) << (fp.mantissa_width - 3)),
    TestFloatingPoint(true, 0 + exp_offset, BigInt(4) << (fp.mantissa_width - 3))
  )
  test(
    TestFloatingPoint(false, -2 + exp_offset, BigInt(1) << (fp.mantissa_width - 3)),
    TestFloatingPoint(true, 0 + exp_offset, BigInt(4) << (fp.mantissa_width - 3))
  )
}

class AddUnitExhaustiveTester(dut: OpAdd) extends FloatingPointBinaryOpTester(dut, _ + _) {
  implicit val random: Random = new Random(System.currentTimeMillis())

  println("normals")

  test(TestFloatingPoint(false, 123, 1), TestFloatingPoint(false, 123, 4))
  test(TestFloatingPoint(false, 123, 1), TestFloatingPoint(true, 123, 4))
  test(TestFloatingPoint(false, 121, 1), TestFloatingPoint(true, 123, 4))

  println("random tests")
  for (i <- (0 until 8192)) {
    val fp1 = TestFloatingPoint.random
    val fp2 = TestFloatingPoint.random
    test(fp1, fp2)
  }

  println("random tests for same-mantissa numbers")
  for (i <- (0 until 8192)) {
    val fp1 = TestFloatingPoint.random
    val fp2 = TestFloatingPoint.random
    fp2.mantissa = fp1.mantissa

    fp1.exponent = Math.max(fp1.exponent, 1)
    fp2.exponent = Math.max(fp2.exponent, 1)

    test(fp1, fp2)
  }

  println("random tests for same-exponent numbers")
  for (i <- (0 until 8192)) {
    val fp1 = TestFloatingPoint.random
    val fp2 = TestFloatingPoint.random

    fp1.exponent = Math.max(fp1.exponent, 1)
    fp2.exponent = Math.max(fp2.exponent, 1)
    test(fp1, fp2)
  }
}

import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class AddTester extends AnyFlatSpec with ChiselScalatestTester {
  /*
  "Add" should "create correct sum result for basic tests." in {
    for (i <- 3 to 6) {
      test(new OpAdd(FloatingPoint(i, i), true)) { dut =>
        new AddUnitBasicTester(dut)
      }

      test(new OpAdd(FloatingPoint(i, i), false)) { dut =>
        new AddUnitBasicTester(dut)
      }
    }
  }
   */

  "Add" should "create acceptable results for exhaustive tests." in {
    // test(new OpAdd(FloatingPoint(11, 52), false)).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
    //   new AddUnitExhaustiveTester(dut)
    // }

    test(new OpAdd(FloatingPoint(11, 52), true)) { dut =>
      new AddUnitExhaustiveTester(dut)
    }
  }
}
