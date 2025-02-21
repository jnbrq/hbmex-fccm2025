package hbmex.components.stripe

import chisel3._
import chisel3.util._

import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class AddressTransformTester extends AnyFlatSpec with ChiselScalatestTester {
  val transformations = Seq(
    Seq(32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
    Seq(32, 31, 30, 29, 14, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 28, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
    Seq(32, 31, 30, 15, 14, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 29, 28, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
    Seq(32, 31, 16, 15, 14, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 30, 29, 28, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
    Seq(32, 17, 16, 15, 14, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 31, 30, 29, 28, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
    Seq(18, 17, 16, 15, 14, 27, 26, 25, 24, 23, 22, 21, 20, 19, 32, 31, 30, 29, 28, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,

    // for failsafe
    Seq(32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
    Seq(32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse
  )

  def printBinary(value: BigInt, width: Int): Unit = {
    val binaryString = value.toString(2)
    val paddedBinary = binaryString.reverse.padTo(width, '0').reverse
    println("0b" + paddedBinary.takeRight(width))
  }

  "AddressTransform" should "work" in {
    test(new AddressTransform(33, transformations)).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      {
        dut.in.poke(7 << 14)

        dut.select.poke(0)
        printBinary(dut.out.peekInt(), 33)

        dut.select.poke(1)
        printBinary(dut.out.peekInt(), 33)

        dut.select.poke(2)
        printBinary(dut.out.peekInt(), 33)

        dut.select.poke(3)
        printBinary(dut.out.peekInt(), 33)
      }
    }
  }
}
