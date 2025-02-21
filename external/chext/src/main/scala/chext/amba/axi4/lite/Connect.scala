package chext.amba.axi4.lite

import chext.elastic.ConnectOp._

private object connect {
  def apply(master: Interface, slave: Interface): Unit = {
    val masterCfg = master.cfg.copy(wAddr = 0)
    val slaveCfg = slave.cfg.copy(wAddr = 0)
    assert(masterCfg == slaveCfg)

    if (master.cfg.read) {
      master.ar :=> slave.ar
      slave.r :=> master.r
    }

    if (master.cfg.write) {
      master.aw :=> slave.aw
      master.w :=> slave.w
      slave.b :=> master.b
    }
  }
}

trait ConnectOp {
  /* implicit class names should be different, otherwise shadowed */
  implicit class axi4_lite_connect_op(master: Interface) {
    def :=>(slave: Interface) = {
      connect(master, slave)
    }
  }
}

object ConnectOp extends ConnectOp
