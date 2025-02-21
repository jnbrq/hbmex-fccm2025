package chext.amba.axi4s

import chisel3._
import chisel3.util._
import chisel3.experimental.dataview._

case class Config(
    val wData: Int,
    val onlyRV: Boolean = false,
    val wId: Int = 0,
    val wDest: Int = 0,
    val wUser: Int = 0
) {
  require(wData % 8 == 0)

  val wStrobe = wData / 8
  val wKeep = wStrobe
}

class Interface(val cfg: Config) extends Bundle {
  val TREADY = Input(Bool())
  val TVALID = Output(Bool())
  val TDATA = Output(UInt(cfg.wData.W))
  val TSTRB = if (!cfg.onlyRV) Some(Output(UInt(cfg.wStrobe.W))) else None
  val TKEEP = if (!cfg.onlyRV) Some(Output(UInt(cfg.wKeep.W))) else None
  val TLAST = if (!cfg.onlyRV) Some(Output(Bool())) else None
  val TID =
    if (!cfg.onlyRV && cfg.wId > 0) Some(Output(UInt(cfg.wId.W))) else None
  val TDEST =
    if (!cfg.onlyRV && cfg.wDest > 0) Some(Output(UInt(cfg.wDest.W))) else None
  val TUSER =
    if (!cfg.onlyRV && cfg.wUser > 0) Some(Output(UInt(cfg.wUser.W))) else None
}

object Master {

  /** create an AXI4-stream master interface with the given configuration. */
  def apply(cfg: Config) = Interface(cfg)
}

object Slave {

  /** create an AXI4-stream slave interface with the given configuration. */
  def apply(cfg: Config) = Flipped(Interface(cfg))
}

object Interface {
  def apply(cfg: Config): Interface = new Interface(cfg)

  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val view = DataView[Interface, IrrevocableIO[UInt]](
    interface => Irrevocable(UInt(interface.cfg.wData.W)),
    _.TREADY -> _.ready,
    _.TVALID -> _.valid,
    _.TDATA -> _.bits
  )
}
