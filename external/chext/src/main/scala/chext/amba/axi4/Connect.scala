package chext.amba.axi4

import chisel3._
import chisel3.util._

import chext.amba.axi4

object connect {
  import axi4.Casts._
  import axi4.full.ConnectOp._
  import axi4.lite.ConnectOp._

  def apply(master: axi4.RawInterface, slave: axi4.full.Interface): Unit = {
    master.asFull :=> slave
  }

  def apply(master: axi4.RawInterface, slave: axi4.lite.Interface): Unit = {
    master.asLite :=> slave
  }

  def apply(master: axi4.RawInterface, slave: axi4.RawInterface): Unit = {
    if (master.cfg.lite)
      master.asLite :=> slave.asLite
    else
      master.asFull :=> slave.asFull
  }
}

trait ConnectOp {
  /* implicit class names should be different, otherwise shadowed */
  implicit class axi4_connect_op(master: axi4.RawInterface) {
    def :=>(slave: axi4.RawInterface) = {
      connect(master, slave)
    }

    def :=>(slave: axi4.full.Interface) = {
      connect(master, slave)
    }

    def :=>(slave: axi4.lite.Interface) = {
      connect(master, slave)
    }
  }
}

object ConnectOp extends ConnectOp
