package chext.ip.memory

abstract class Target {
  def name: String

  def createSinglePortRawROM(cfg: RawMemConfig): RawMem
  def createSimpleDualPortRawROM(cfg: RawMemConfig): RawMem
  def createTrueDualPortRawROM(cfg: RawMemConfig): RawMem

  def createSinglePortRawRAM(cfg: RawMemConfig): RawMem
  def createSimpleDualPortRawRAM(cfg: RawMemConfig): RawMem
  def createTrueDualPortRawRAM(cfg: RawMemConfig): RawMem
}

object Target {
  def current: Target = {
    if (current_.isEmpty)
      throw new RuntimeException("Current target is not set!")
    current_.get
  }

  def setCurrent(target: Target): Unit = current_ = Some(target)

  private var current_ = Some(chisel.Target): Option[Target]
}
