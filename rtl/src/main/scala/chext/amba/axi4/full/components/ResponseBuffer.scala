package chext.amba.axi4.full.components

import chisel3._
import chisel3.util._
import chisel3.experimental.prefix

import chext.elastic
import elastic.ConnectOp._

import chext.amba.axi4
import axi4.Ops._

private class CounterEx(maxExclusive: Int) extends Module {
  val wCounter = log2Ceil(maxExclusive)

  val io = IO(new Bundle {
    val up = Input(UInt(wCounter.W))
    val down = Input(UInt(wCounter.W))

    val used = Output(UInt(wCounter.W))
    val left = Output(UInt(wCounter.W))
  })

  private val rUsed = RegInit(0.U(wCounter.W))
  private val rLeft = RegInit((maxExclusive - 1).U(wCounter.W))

  when(io.up > io.down) {
    rUsed := rUsed + (io.up - io.down)
    rLeft := rLeft - (io.up - io.down)
  }.otherwise {
    rUsed := rUsed - (io.down - io.up)
    rLeft := rLeft + (io.down - io.up)
  }

  io.used := rUsed
  io.left := rLeft

  def canUp(x: UInt) = io.left >= x
  def canDown(x: UInt) = io.used >= x

  def up(x: UInt) = io.up := x
  def down(x: UInt) = io.down := x

  def noUp() = up(0.U)
  def noDown() = down(0.U)
}

case class ResponseBufferConfig(
    val axiCfg: axi4.Config,
    val bufLengthR: Int = 2,
    val bufLengthB: Int = 2,
    val writePassThrough: Boolean = false,
    val readPassThrough: Boolean = false
) {
  require(bufLengthR >= 2)
  require(bufLengthB >= 2)
}

class ResponseBuffer(cfg: ResponseBufferConfig) extends Module {
  import cfg._

  val s_axi = IO(axi4.full.Slave(axiCfg))
  val m_axi = IO(axi4.full.Master(axiCfg))

  def implRead(): Unit = prefix("read") {
    val ctrR = Module(new CounterEx(bufLengthR + 1))

    ctrR.noUp()
    ctrR.noDown()

    val arrival0 = new elastic.Arrival(s_axi.ar, m_axi.ar) {
      protected def onArrival: Unit = {
        out := in
        val len = in.len +& 1.U

        when(ctrR.canUp(len)) {
          ctrR.up(len)

          accept()
        }.otherwise {
          noAccept()
        }
      }
    }

    val arrival1 = new elastic.Arrival(elastic.SourceBuffer(m_axi.r, bufLengthR), s_axi.r) {
      protected def onArrival: Unit = {
        out := in

        ctrR.down(1.U)
        accept()
      }
    }
  }

  def implWrite(): Unit = prefix("write") {
    val ctrB = Module(new chext.util.Counter(bufLengthB + 1))

    ctrB.noDec()
    ctrB.noInc()

    val arrival0 =
      new elastic.Arrival(s_axi.aw, m_axi.aw) {
        protected def onArrival: Unit = {
          out := in

          when(ctrB.notFull) {
            ctrB.inc()

            accept()
          }.otherwise {
            noAccept()
          }
        }
      }

    val arrival1 = new elastic.Arrival(elastic.SourceBuffer(m_axi.b, bufLengthB), s_axi.b) {
      protected def onArrival: Unit = {
        out := in

        ctrB.dec()
        accept()
      }
    }

    s_axi.w :=> m_axi.w
  }

  if (axiCfg.read) {
    if (readPassThrough) {
      s_axi.ar :=> m_axi.ar
      m_axi.r :=> s_axi.r
    } else
      implRead()
  }

  if (axiCfg.write) {
    if (writePassThrough) {
      s_axi.aw :=> m_axi.aw
      s_axi.w :=> m_axi.w
      m_axi.b :=> s_axi.b
    } else
      implWrite()
  }

}
