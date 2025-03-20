package chext.amba.axi4.full

import chext.elastic.ConnectOp._

private object connect {
  def apply(master: Interface, slave: Interface): Unit = {
    assert(
      master.cfg.wId <= slave.cfg.wId,
      "The master interface should have a narrow ID field than the slave interface."
    )

    assert(master.cfg.axi3Compat || !slave.cfg.axi3Compat)

    val masterCfg = master.cfg.copy(wId = 0, wAddr = 0, axi3Compat = false)
    val slaveCfg = slave.cfg.copy(wId = 0, wAddr = 0, axi3Compat = false)
    assert(masterCfg == slaveCfg, "Configurations do not match.")

    assert(
      !masterCfg.axi3Compat && !slaveCfg.axi3Compat || masterCfg.axi3Compat,
      "A master interface that is not AXI3-compatible cannot drive an AXI3-compatible interface."
    )

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
  implicit class axi4_full_connect_op(master: Interface) {
    def :=>(slave: Interface) = {
      connect(master, slave)
    }
  }
}

object ConnectOp extends ConnectOp
