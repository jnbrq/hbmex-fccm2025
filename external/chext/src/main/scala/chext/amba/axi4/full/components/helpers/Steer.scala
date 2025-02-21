package chext.amba.axi4.full.components.helpers

import chisel3._
import chisel3.util._

class SteerLeft(val wDataInput: Int, val wDataOutput: Int) extends Module {
  require(isPow2(wDataInput), "'isPow2(wDataInput)' must be true!")
  require(isPow2(wDataOutput), "'isPow2(wDataOutput)' must be true!")
  require(wDataOutput >= wDataInput, "'wDataOutput >= wDataInput' must be true!")

  val wOffset = log2Ceil(wDataOutput) - log2Ceil(wDataInput)

  val dataIn = IO(Input(UInt(wDataInput.W)))
  val offsetIn = IO(Input(UInt(wOffset.W)))
  val dataOut = IO(Output(UInt(wDataOutput.W)))

  private val shifted = VecInit.tabulate(1 << wOffset) {
    case (shift) => {
      val zerosMsb = ((1 << wOffset) - (1 + shift)) * wDataInput
      val zerosLsb = (shift) * wDataInput
      Cat(0.U(zerosMsb.W), dataIn, 0.U(zerosLsb.W))
    }
  }

  dataOut := shifted(offsetIn)
}

class SteerRight(val wDataInput: Int, val wDataOutput: Int) extends Module {
  require(isPow2(wDataInput), "'isPow2(wDataInput)' must be true!")
  require(isPow2(wDataOutput), "'isPow2(wDataOutput)' must be true!")
  require(wDataOutput <= wDataInput, "'wDataOutput <= wDataInput' must be true!")
  val wOffset = log2Ceil(wDataInput) - log2Ceil(wDataOutput)

  val dataIn = IO(Input(UInt(wDataInput.W)))
  val offsetIn = IO(Input(UInt(wOffset.W)))
  val dataOut = IO(Output(UInt(wDataOutput.W)))

  private val substrings = VecInit.tabulate(1 << wOffset) {
    case (index) => {
      val lsbIndex = index * wDataOutput
      val msbIndex = (index + 1) * wDataOutput - 1
      dataIn(msbIndex, lsbIndex)
    }
  }

  dataOut := substrings(offsetIn)
}
