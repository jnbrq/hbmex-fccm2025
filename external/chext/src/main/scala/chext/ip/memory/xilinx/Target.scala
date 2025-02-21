package chext.ip.memory.xilinx

import chext.ip.memory

case object Target extends memory.Target {
  val name = "Xilinx"

  def createSinglePortRawROM(cfg: memory.RawMemConfig): memory.RawMem =
    ???

  def createSimpleDualPortRawROM(cfg: memory.RawMemConfig): memory.RawMem =
    ???

  def createTrueDualPortRawROM(cfg: memory.RawMemConfig): memory.RawMem =
    ???

  def createSinglePortRawRAM(cfg: memory.RawMemConfig): memory.RawMem =
    new SinglePortRawMem(cfg)

  def createSimpleDualPortRawRAM(cfg: memory.RawMemConfig): memory.RawMem =
    new SimpleDualPortRawMem(cfg)

  def createTrueDualPortRawRAM(cfg: memory.RawMemConfig): memory.RawMem =
    new TrueDualPortRawMem(cfg)
}
