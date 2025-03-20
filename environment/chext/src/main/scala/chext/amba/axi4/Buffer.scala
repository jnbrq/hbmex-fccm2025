package chext.amba.axi4

import chisel3._

import chext.amba.axi4
import axi4.Casts._

case class BufferConfig(
    aw: Int = 0,
    w: Int = 0,
    b: Int = 0,
    ar: Int = 0,
    r: Int = 0
) {
  require(aw >= 0)
  require(w >= 0)
  require(b >= 0)
  require(ar >= 0)
  require(r >= 0)
}

object BufferConfig {
  def all(n: Int) = BufferConfig(n, n, n, n, n)
}

object buffer {
  def apply(
      master: RawInterface,
      slave: RawInterface,
      cfg: BufferConfig
  ): Unit = {
    assert(master.cfg == slave.cfg)

    if (master.cfg.lite)
      lite.buffer(master.asLite, slave.asLite, cfg)
    else
      full.buffer(master.asFull, slave.asFull, cfg)
  }
}

object SlaveBuffer {
  def apply(
      interface: RawInterface,
      cfg: BufferConfig
  ): RawInterface = {
    val result = Wire(Slave(interface.cfg))
    buffer(interface, result, cfg)
    result
  }
}

object MasterBuffer {
  def apply(
      interface: RawInterface,
      cfg: BufferConfig
  ): RawInterface = {
    val result = Wire(Master(interface.cfg))
    buffer(result, interface, cfg)
    result
  }
}
