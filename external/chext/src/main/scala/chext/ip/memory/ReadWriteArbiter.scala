package chext.ip.memory

import chisel3._
import chisel3.util._

trait ReadWriteArbiter extends Module {
  def wrReq: Bool
  def rdReq: Bool
  def chooseRd: Bool
}

object ReadWriteArbiter {
  type Func = () => ReadWriteArbiter
  val defaultFunc = () => new BasicReadWriteArbiter(8)
}

/** @param maxCount
  *   Determines when the arbiter decision changes if there is a long burst of reads/writes. Should
  *   be at least 1.
  */
class BasicReadWriteArbiter(maxCount: Int) extends Module with ReadWriteArbiter {
  require(maxCount > 0)

  val stRead = 0
  val stWrite = 1

  val rdReq = IO(Input(Bool()))
  val wrReq = IO(Input(Bool()))
  val chooseRd = IO(Output(Bool()))

  private val state = RegInit(stRead.U(1.W))
  private val count = RegInit(0.U(log2Up(maxCount).W))

  chooseRd := state === stRead.U

  private def switchTo(nextState: Int): Unit = {
    count := 0.U
    state := nextState.U
  }

  when(state === stRead.U) {
    when(!rdReq) {
      switchTo(stWrite)
    }.otherwise {
      when(count === (maxCount - 1).U) {
        switchTo(stWrite)
      }.otherwise {
        count := count + 1.U
      }
    }
  }.otherwise {
    when(!wrReq) {
      switchTo(stRead)
    }.otherwise {
      when(count === (maxCount - 1).U) {
        switchTo(stRead)
      }.otherwise {
        count := count + 1.U
      }
    }
  }
}

class ReadOnlyArbiter extends Module with ReadWriteArbiter {
  val rdReq = IO(Input(Bool()))
  val wrReq = IO(Input(Bool()))
  val chooseRd = IO(Output(Bool()))

  chooseRd := true.B
}

class WriteOnlyArbiter extends Module with ReadWriteArbiter {
  val rdReq = IO(Input(Bool()))
  val wrReq = IO(Input(Bool()))
  val chooseRd = IO(Output(Bool()))

  chooseRd := false.B
}
