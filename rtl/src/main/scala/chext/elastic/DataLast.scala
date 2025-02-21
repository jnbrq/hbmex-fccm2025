package chext.elastic

import chisel3._

class DataLast(wData: Int) extends Bundle {
  val data = UInt(wData.W)
  val last = Bool()
}
