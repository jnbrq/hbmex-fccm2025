package chext.ip.sgdma

import chisel3._
import chisel3.util._

import chext.amba.axi4
import chext.elastic
import chext.ip.memory

case class WriteBufferConfig(
    val bufLengthW: Int = 64,
    val bufLengthAW: Int = 2
)

class WriteBuffer(val axiCfg: axi4.Config, val cfg: WriteBufferConfig) extends Module {
  import cfg._
  private implicit val _axiCfg: axi4.Config = axiCfg

  require(bufLengthW >= 1)
  require(bufLengthAW >= 1)
  require(axiCfg.write && !axiCfg.lite)

  val source = IO(new Bundle {
    val aw = elastic.Source(Irrevocable(new axi4.full.WriteAddressChannel))
    val w = elastic.Source(Irrevocable(new axi4.full.WriteDataChannel))
  })

  val sink = IO(new Bundle {
    val aw = elastic.Sink(Irrevocable(new axi4.full.WriteAddressChannel))
    val w = elastic.Sink(Irrevocable(new axi4.full.WriteDataChannel))
  })

  private val ctrAddr = Module(new chext.util.Counter(bufLengthW + 1))

  ctrAddr.noDec()
  ctrAddr.noInc()

  private val arrival1 =
    new elastic.Arrival(source.w, elastic.SinkBuffer(sink.w, bufLengthW)) {
      protected def onArrival: Unit = {
        out := in

        when(in.last) {
          when(ctrAddr.notFull) {
            ctrAddr.inc()
            accept()
          }.otherwise {
            noAccept()
          }
        }.otherwise {
          accept()
        }
      }
    }

  private val arrival2 =
    new elastic.Arrival(elastic.SourceBuffer(source.aw, bufLengthAW), sink.aw) {
      protected def onArrival: Unit = {
        out := in

        when(ctrAddr.notZero) {
          ctrAddr.dec()
          accept()
        }.otherwise {
          noAccept()
        }
      }
    }
}

object WriteBuffer {
  def apply(
      master: axi4.full.Interface,
      slave: axi4.full.Interface,
      cfg: WriteBufferConfig = WriteBufferConfig()
  ) = {
    require(master.cfg == slave.cfg)

    val writeBuffer = Module(new WriteBuffer(axiCfg = master.cfg, cfg))

    import axi4.full.WriteAddressChannel
    import elastic.ConnectOp._

    master.ar :=> slave.ar
    slave.r :=> master.r

    master.aw :=> writeBuffer.source.aw
    writeBuffer.sink.aw :=> slave.aw.asInstanceOf[IrrevocableIO[WriteAddressChannel]]

    master.w :=> writeBuffer.source.w
    writeBuffer.sink.w :=> slave.w

    slave.b :=> master.b
  }
}
