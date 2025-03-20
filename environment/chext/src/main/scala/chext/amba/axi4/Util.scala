package chext.amba.axi4.util

/* Exceptions */

object NotSupported {
  def apply(str: String) = new RuntimeException(f"Not supported: $str")
}

object BadConfig {
  def apply(str: String) = new RuntimeException(f"Bad config: $str")
}

/* Hardware utilities */

import chisel3._

object writeStrobeLogic {

  /** Implements logic for write strobe */
  def apply(original: Bits, wdata: Bits, wstrb: Bits): Bits = {
    require(original.getWidth == wdata.getWidth)
    require(wstrb.getWidth == original.getWidth / 8)

    VecInit(
      wstrb.asBools.zipWithIndex.map {
        case (strobe, idx) => {
          val byte_wdata = wdata((idx + 1) * 8 - 1, idx * 8)
          val byte_original = original((idx + 1) * 8 - 1, idx * 8)
          Mux(strobe, byte_wdata, byte_original)
        }
      }
    ).asUInt
  }
}
