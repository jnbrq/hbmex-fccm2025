package chext.amba.axi4.full

import chisel3._
import chisel3.util._

import chext.amba.axi4.BufferConfig
import chext.elastic.{SinkBuffer, SourceBuffer}
import chext.elastic.ConnectOp._

object buffer {
  private[full] def insertBufferR(
      master: Interface,
      slave: Interface,
      cfg: BufferConfig
  ): Unit = {
    SourceBuffer(master.ar, cfg.ar) :=> slave.ar
    slave.r :=> SinkBuffer(master.r, cfg.r)
  }

  private[full] def insertBufferW(
      master: Interface,
      slave: Interface,
      cfg: BufferConfig
  ): Unit = {
    SourceBuffer(master.aw, cfg.aw) :=> slave.aw
    SourceBuffer(master.w, cfg.w) :=> slave.w
    slave.b :=> SinkBuffer(master.b, cfg.b)
  }

  /** Inserts a buffer between a master and a slave interface.
    *
    * @param master
    * @param slave
    * @param cfg
    */
  def apply(
      master: Interface,
      slave: Interface,
      cfg: BufferConfig
  ): Unit = {
    assert(master.cfg == slave.cfg)

    if (master.cfg.read)
      insertBufferR(master, slave, cfg)

    if (master.cfg.write)
      insertBufferW(master, slave, cfg)
  }
}

object SlaveBuffer {
  def apply(
      interface: Interface,
      cfg: BufferConfig
  ): Interface = {
    val result = Wire(Slave(interface.cfg))
    buffer(interface, result, cfg)
    result
  }
}

object MasterBuffer {
  def apply(
      interface: Interface,
      cfg: BufferConfig
  ): Interface = {
    val result = Wire(Master(interface.cfg))
    buffer(result, interface, cfg)
    result
  }
}
