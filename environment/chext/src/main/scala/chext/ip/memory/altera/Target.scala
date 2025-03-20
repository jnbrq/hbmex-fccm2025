package chext.ip.memory.altera

import chext.ip.memory

case object Target extends memory.Target {
  val name: String = "Altera"

  def createSinglePortRawROM(cfg: memory.RawMemConfig): memory.RawMem =
    ???

  def createSimpleDualPortRawROM(cfg: memory.RawMemConfig): memory.RawMem =
    ???

  def createTrueDualPortRawROM(cfg: memory.RawMemConfig): memory.RawMem =
    ???

  def createSinglePortRawRAM(cfg: memory.RawMemConfig): memory.RawMem =
    ???

  def createSimpleDualPortRawRAM(cfg: memory.RawMemConfig): memory.RawMem =
    ???

  def createTrueDualPortRawRAM(cfg: memory.RawMemConfig): memory.RawMem =
    ???
}
