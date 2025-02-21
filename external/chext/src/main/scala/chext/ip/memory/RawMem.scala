package chext.ip.memory

import chisel3._
import chisel3.util._

case class RawMemConfig(
    val wAddr: Int = 10,
    val wData: Int = 32,
    val latencyRead: Int = 2,

    /** @note Not used in case of ROM. */
    val latencyWrite: Int = 1

    /** @note
      *   TODO: To support ROMs, extend this structure with an initial content field. Maybe, it
      *   should be loaded from a file or the contents are given inline?
      */
) {
  require(latencyRead >= 0)
  require(latencyWrite >= 0)

  require(wData >= 8 && wData % 8 == 0)
}

trait RawMem extends Module {
  def cfg: RawMemConfig
  def getPorts: Seq[RawInterface]
}
