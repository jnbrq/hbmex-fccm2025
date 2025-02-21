package chext.ip.memory.chisel

import chext.ip.memory

case object Target extends memory.Target {
  val name = "Chisel"

  def createSinglePortRawROM(cfg: memory.RawMemConfig): memory.RawMem =
    ???

  def createSimpleDualPortRawROM(cfg: memory.RawMemConfig): memory.RawMem =
    ???

  def createTrueDualPortRawROM(cfg: memory.RawMemConfig): memory.RawMem =
    ???

  def createSinglePortRawRAM(cfg: memory.RawMemConfig): memory.RawMem =
    new SinglePortRawRAM(cfg)

  def createSimpleDualPortRawRAM(cfg: memory.RawMemConfig): memory.RawMem =
    new SimpleDualPortRawRAM(cfg)

  def createTrueDualPortRawRAM(cfg: memory.RawMemConfig): memory.RawMem =
    new TrueDualPortRawRAM(cfg)
}
