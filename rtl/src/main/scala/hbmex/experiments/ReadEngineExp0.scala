package hbmex.experiments

import chisel3._
import chisel3.util._

import chext.amba.axi4
import axi4.Ops._

import hbmex.components.read_engine

case class ReadEngineExp0Config(val desiredName: String = "ReadEngineExp0") {
  val wId = 6
  val wAddr = 34

  val readEngineCfg = read_engine.Config(
    axi4.Config(
      wId = wId,
      wAddr = wAddr,
      wData = 256,
      axi3Compat = true,
      hasQos = false,
      hasProt = false,
      hasCache = false,
      hasRegion = false,
      hasLock = false
    )
  )
}

class ReadEngineExp0(cfg: ReadEngineExp0Config = ReadEngineExp0Config()) extends Module {
  import cfg._
  override val desiredName: String = f"${cfg.desiredName}"

  val S_AXI_CONTROL = IO(axi4.Slave(readEngineCfg.axiCtrlCfg))
  val S_AXI_DESC = IO(axi4.Slave(readEngineCfg.axiDescCfg))

  val M_AXI = IO(axi4.Master(readEngineCfg.axiMasterCfg))

  private val readEngine0 = Module(new read_engine.ReadEngine(readEngineCfg))

  S_AXI_CONTROL.asLite :=> readEngine0.s_axi_ctrl
  S_AXI_DESC.asFull :=> readEngine0.s_axi_desc
  readEngine0.m_axi :=> M_AXI.asFull

  readEngine0.start := false.B
}

object EmitReadEngineExp0 extends App {
  emitVerilog(new ReadEngineExp0(ReadEngineExp0Config()))
}
