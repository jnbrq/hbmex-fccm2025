package hbmex.components.read_engine

import chisel3._
import chisel3.util._

class Desc extends Bundle {
  val addr = UInt(42.W)
  val id = UInt(12.W)
  val len = UInt(8.W)

  val flags = UInt(2.W)
}

object Flags {
  val WAIT = 0.toLong
  val ADDR = 1.toLong
  
  // Add new functionality here
}
