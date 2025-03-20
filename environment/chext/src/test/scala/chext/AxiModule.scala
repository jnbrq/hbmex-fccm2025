package chext

import chisel3._
import chisel3.util._

import chext.elastic
import chext.amba.axi4
import chext.ip.memory

import elastic.ConnectOp._
import axi4.Ops._

class AxiModule extends Module {
  val axiCfg = axi4.Config(wId = 8, wAddr = 12, wData = 64)
  val S_AXI = IO(axi4.Slave(axiCfg))

  val axiLiteCfg = axi4.Config(wAddr = 12, wData = 64, lite = true)
  val S_AXI_LITE = IO(axi4.Slave(axiLiteCfg))

  private val rawMemCfg = memory.RawMemConfig(
    axiCfg.wAddr - log2Ceil(axiCfg.wData / 8),
    axiCfg.wData,
    8,
    8
  )

  private val portCfgRead = memory.PortConfig(
    8,
    8,
    () => new memory.ReadOnlyArbiter
  )

  private val portCfgWrite = memory.PortConfig(
    8,
    8,
    () => new memory.WriteOnlyArbiter
  )

  private val ram = Module(
    new memory.TrueDualPortRAM(rawMemCfg, portCfgRead, portCfg2 = portCfgWrite)
  )

  private val bridge = Module(new memory.Axi4FullToReadWriteBridge(axiCfg))

  S_AXI :=> bridge.s_axi

  bridge.read.req :=> ram.read1.req
  ram.read1.resp :=> bridge.read.resp

  ram.write1.req.noenq()
  ram.write1.resp.nodeq()

  ram.read2.req.noenq()
  ram.read2.resp.nodeq()

  bridge.write.req :=> ram.write2.req
  ram.write2.resp :=> bridge.write.resp

  val registerBlock = new axi4.lite.components.RegisterBlock(12, 64, 12)

  S_AXI_LITE :=> registerBlock.s_axil

  when(registerBlock.wrReq) {
    registerBlock.wrOk()
  }

  when(registerBlock.rdReq) {
    registerBlock.rdOk(registerBlock.rdAddr | 0x0abc_d000.U)
  }
}

object EmitAxiModule extends App {
  emitVerilog(new AxiModule)
}
