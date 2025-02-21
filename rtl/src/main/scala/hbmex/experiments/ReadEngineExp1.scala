package hbmex.experiments

import chisel3._
import chisel3.util._

import chext.amba.axi4
import axi4.Ops._

import hbmex.components.read_engine

case class ReadEngineExp1Config(val desiredName: String = "ReadEngineExp1") {
  val wId = 6
  val wAddr = 34

  val readEngineCfg = read_engine.Config(
    axi4.Config(
      wId = wId,
      wAddr = wAddr,
      wData = 256
    )
  )
}

class ReadEngineExp1(cfg: ReadEngineExp1Config = ReadEngineExp1Config()) extends Module {
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

object EmitReadEngineExp1 extends App {
  emitVerilog(new ReadEngineExp1(ReadEngineExp1Config()))
}
