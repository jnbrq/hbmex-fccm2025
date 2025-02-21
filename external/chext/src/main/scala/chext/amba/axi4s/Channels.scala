package chext.amba.axi4s

import chisel3._
import chisel3.experimental.dataview.PartialDataView
import chisel3.util.IrrevocableIO
import chisel3.util.Irrevocable

class FullChannel(cfg: Config) extends Bundle {
  val data = Bits(cfg.wData.W)
  val strobe = UInt(cfg.wStrobe.W)
  val keep = UInt(cfg.wKeep.W)
  val last = Bool()
  val id = if (cfg.wId > 0) Some(UInt(cfg.wId.W)) else None
  val dest = if (cfg.wDest > 0) Some(UInt(cfg.wDest.W)) else None
  val user = if (cfg.wUser > 0) Some(UInt(cfg.wUser.W)) else None
}

object FullChannel {
  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val view1 = PartialDataView.mapping[Interface, IrrevocableIO[FullChannel]](
    interface => Irrevocable(new FullChannel(interface.cfg)),
    (interface, irrevocable) => Seq[Tuple2[Option[Data], Option[Data]]](
      Some(interface.TREADY) -> Some(irrevocable.ready),
      Some(interface.TVALID) -> Some(irrevocable.valid),
      Some(interface.TDATA) -> Some(irrevocable.bits.data),
      interface.TSTRB -> Some(irrevocable.bits.strobe),
      interface.TKEEP -> Some(irrevocable.bits.keep),
      interface.TLAST -> Some(irrevocable.bits.last),
      interface.TID -> irrevocable.bits.id,
      interface.TDEST -> irrevocable.bits.dest,
      interface.TUSER -> irrevocable.bits.user
    )
      .filter { case (a, b) => a.nonEmpty && b.nonEmpty }
      .map { case (a, b) => a.get -> b.get }
  )
}

object BasicChannel {
  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val view2 = PartialDataView.mapping[Interface, IrrevocableIO[Bits]](
    interface => Irrevocable(Bits(interface.cfg.wData.W)),
    (interface, irrevocable) => Seq[Tuple2[Data, Data]](
      interface.TREADY -> irrevocable.ready,
      interface.TVALID -> irrevocable.valid,
      interface.TDATA -> irrevocable.bits
    )
  )
}
