package chext.amba.axi4s

import chisel3._
import chisel3.util._
import chisel3.experimental.dataview._

object Casts {
  implicit class viewAxisInterfaceAs(x: Interface) {
    import FullChannel._
    import BasicChannel._

    @deprecated("Please use asLite instead, this will be removed.")
    def lite = x.viewAs[IrrevocableIO[Bits]]

    @deprecated("Please use asFull instead, this will be removed.")
    def full = x.viewAs[IrrevocableIO[FullChannel]]

    def asLite = x.viewAs[IrrevocableIO[Bits]]
    def asFull = x.viewAs[IrrevocableIO[FullChannel]]
  }
}
