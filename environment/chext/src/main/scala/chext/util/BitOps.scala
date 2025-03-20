package chext.util

import chisel3._
import chisel3.util._

object BitOps {
  implicit class UIntOps_impl(x: UInt) {
    val width = x.getWidth

    /** Creates a mask whose least-significant n bits are set.
      *
      * @param n
      * @return
      */
    private def makeLsbMaskN(n: Int): UInt = {
      if (n == width)
        ~0.U(width.W)
      else
        (0.U((width - n - 1).W) ## 1.U(1.W) ## 0.U(n.W)) -% 1.U
    }

    private def makeMsbMaskN(n: Int): UInt = ~makeLsbMaskN(width - n)

    /** Returns a copy of `x` with least-significant n bits are reset.
      *
      * @param n
      * @return
      */
    def resetLsbN(n: Int): UInt = {
      chisel3.experimental.requireIsHardware(x)

      require(n >= 0 && n <= width)
      x & ~makeLsbMaskN(n)
    }

    def resetMsbN(n: Int): UInt = {
      chisel3.experimental.requireIsHardware(x)

      require(n >= 0 && n <= width)
      x & ~makeMsbMaskN(n)
    }

    /** Returns a copy of `x` with last n bits are set.
      *
      * @param n
      * @return
      */
    def setLsbN(n: Int): UInt = {
      chisel3.experimental.requireIsHardware(x)

      require(n >= 0 && n <= width)
      x | makeLsbMaskN(n)
    }

    def setMsbN(n: Int): UInt = {
      chisel3.experimental.requireIsHardware(x)

      require(n >= 0 && n <= width)
      x | makeMsbMaskN(n)
    }

    def lsbN(n: Int): UInt = {
      chisel3.experimental.requireIsHardware(x)

      require(n >= 0 && n <= width)

      if (n == 0)
        0.U(0.W)
      else
        x(n - 1, 0)
    }

    def dropLsbN(n: Int): UInt = msbN(width - n)

    def msbN(n: Int): UInt = {
      chisel3.experimental.requireIsHardware(x)

      require(n >= 0 && n <= width)
      if (n == 0)
        0.U(0.W)
      else
        x(width - 1, width - n)
    }

    def dropMsbN(n: Int) = lsbN(width - n)

    /** Extracts certain bits from `x`, designated by `indices`. Result is little-endian: the index
      * at the end of the list determines the most significant bit.
      *
      * @param indices
      * @return
      */
    def extractLittle(indices: Seq[Int]): UInt = {
      chisel3.experimental.requireIsHardware(x)

      if (x.widthKnown)
        indices.foreach { index => require(index < x.getWidth) }

      if (indices.isEmpty)
        0.U(0.W)
      else {
        WireInit(
          VecInit
            .tabulate(indices.length) { //
              (idx) => { x(indices(idx)) }
            }
            .asUInt
        )
      }
    }

    /** Extracts certain bits from `x`, designated by `indices`. Result is big-endian: the index at
      * the end of the list determines the least significant bit.
      *
      * @param indices
      * @return
      */
    def extractBig(indices: Seq[Int]): UInt = extractLittle(indices.reverse)

    /** Synonym for `extractLittle`.
      *
      * @param indices
      * @return
      */
    def extract(indices: Seq[Int]): UInt = extractLittle(indices)

    /** Drops the bits designated by `indices`.
      *
      * @param indices
      * @return
      */
    def drop(indices: Seq[Int]): UInt = {
      chisel3.experimental.requireIsHardware(x)
      require(x.widthKnown)

      extractLittle((0 until x.getWidth).filter(indices.contains))
    }
  }
}

object EmitTest extends App {
  class MyModule extends Module {
    val in = IO(Input(UInt(8.W)))
    val out1 = IO(Output(UInt(8.W)))
    val out2 = IO(Output(UInt(8.W)))
    val out3 = IO(Output(UInt(8.W)))
    val out4 = IO(Output(UInt(8.W)))
    val out5 = IO(Output(UInt(8.W)))
    val out6 = IO(Output(UInt(8.W)))

    import BitOps._

    out1 := in.setLsbN(3)
    out2 := in.resetLsbN(3)
    out3 := in.setMsbN(3)
    out4 := in.resetMsbN(3)
    out5 := in.extractBig(Seq(4, 3, 0))
    out6 := in.extractBig(Seq(7, 5, 2))
  }

  emitVerilog(new MyModule)
}
