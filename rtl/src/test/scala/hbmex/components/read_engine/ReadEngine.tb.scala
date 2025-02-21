package hbmex.components.read_engine

import chisel3._
import chisel3.util._

import chext.elastic
import elastic.ConnectOp._

import chext.amba.axi4
import axi4.Ops._

import chext.ip.memory

import chext.HasHdlinfoModule

class ReadEngineSim1(val moduleName: String = "ReadEngineSim1") extends Module with HasHdlinfoModule {

  private val axiMasterCfg = axi4.Config(10, 12, 32)
  private val readEngineCfg = Config(
    axiMasterCfg = axiMasterCfg,
    log2numDesc = 12
  )

  override def desiredName: String = moduleName

  val S_AXI_CTRL = IO(axi4.Slave(readEngineCfg.axiCtrlCfg))
  val S_AXI_DESC = IO(axi4.Slave(readEngineCfg.axiDescCfg))
  val S_AXI_DATA = IO(axi4.Slave(readEngineCfg.axiMasterCfg))

  private val readEngine = Module(new ReadEngine(readEngineCfg))

  S_AXI_CTRL.asLite :=> readEngine.s_axi_ctrl
  S_AXI_DESC.asFull :=> readEngine.s_axi_desc

  private val rawMemCfg = memory.RawMemConfig(
    wAddr = axiMasterCfg.wAddr - log2Ceil(axiMasterCfg.wData) + 3,
    wData = axiMasterCfg.wData,
    latencyRead = 4,
    latencyWrite = 4
  )

  private val portCfg = memory.PortConfig(
    numOutstandingRead = 8,
    numOutstandingWrite = 8,
    () => new memory.BasicReadWriteArbiter(maxCount = 16)
  )

  private val mem = Module(
    new memory.TrueDualPortRAM(
      rawMemCfg = rawMemCfg,
      portCfg1 = portCfg,
      portCfg2 = portCfg
    )
  )

  private val bridge1 = Module(
    new memory.Axi4FullToReadWriteBridge(cfg = axiMasterCfg)
  )

  bridge1.read.req :=> mem.read1.req
  mem.read1.resp :=> bridge1.read.resp

  bridge1.write.req :=> mem.write1.req
  mem.write1.resp :=> bridge1.write.resp

  private val bridge2 = Module(
    new memory.Axi4FullToReadWriteBridge(cfg = axiMasterCfg)
  )

  bridge2.read.req :=> mem.read2.req
  mem.read2.resp :=> bridge2.read.resp

  bridge2.write.req :=> mem.write2.req
  mem.write2.resp :=> bridge2.write.resp

  readEngine.m_axi :=> bridge1.s_axi
  S_AXI_DATA :=> bridge2.s_axi

  readEngine.start := false.B

  def hdlinfoModule: hdlinfo.Module = {
    import hdlinfo._
    import io.circe.generic.auto._
    import scala.collection.mutable.ArrayBuffer

    val ports = ArrayBuffer.empty[Port]
    val interfaces = ArrayBuffer.empty[Interface]

    ports.append(
      Port(
        "clock",
        PortDirection.input,
        PortKind.clock,
        PortSensitivity.clockRising,
        associatedReset = "reset"
      )
    )
    ports.append(
      Port(
        "reset",
        PortDirection.input,
        PortKind.reset,
        PortSensitivity.resetActiveHigh,
        associatedClock = "clock"
      )
    )

    interfaces.append(
      Interface(
        "S_AXI_CTRL",
        InterfaceRole.slave,
        InterfaceKind("axi4_rtl"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("config" -> TypedObject(readEngineCfg.axiCtrlCfg))
      )
    )

    interfaces.append(
      Interface(
        "S_AXI_DESC",
        InterfaceRole.slave,
        InterfaceKind("axi4_rtl"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("config" -> TypedObject(readEngineCfg.axiDescCfg))
      )
    )

    interfaces.append(
      Interface(
        "S_AXI_DATA",
        InterfaceRole.slave,
        InterfaceKind("axi4_rtl"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("config" -> TypedObject(readEngineCfg.axiMasterCfg))
      )
    )

    Module(
      moduleName,
      ports.toSeq,
      interfaces.toSeq,
      Map("config" -> TypedObject(this))
    )
  }
}

object ReadEngineSim1_TB extends chext.TestBench {
  emit(new ReadEngineSim1)
}

class ReadEngineMultiSim1(val moduleName: String = "ReadEngineMultiSim1") extends Module with HasHdlinfoModule {
  val log2n = 2

  private val axiMasterCfg = axi4.Config(10, 12, 32)
  private val readEngineCfg = Config(
    axiMasterCfg = axiMasterCfg,
    log2numDesc = 12
  )
  private val readEngineMultiCfg = MultiConfig(
    1 << log2n,
    readEngineCfg
  )

  override def desiredName: String = moduleName

  val S_AXI_CTRL = IO(axi4.Slave(readEngineMultiCfg.axiCtrlCfg))
  val S_AXI_DESC = IO(axi4.Slave(readEngineMultiCfg.axiDescCfg))

  private val readEngineMulti = Module(new ReadEngineMulti(readEngineMultiCfg))
  readEngineMulti.start := false.B

  S_AXI_CTRL.asLite :=> readEngineMulti.s_axi_ctrl
  S_AXI_DESC.asFull :=> readEngineMulti.s_axi_desc

  readEngineMulti.m_axiN.zipWithIndex.foreach {
    case (master, index) => {
      val rawMemCfg = memory.RawMemConfig(
        wAddr = axiMasterCfg.wAddr - log2Ceil(axiMasterCfg.wData) + 3,
        wData = axiMasterCfg.wData,
        latencyRead = 4,
        latencyWrite = 4
      )

      val portCfg = memory.PortConfig(
        numOutstandingRead = 8,
        numOutstandingWrite = 8,
        () => new memory.BasicReadWriteArbiter(maxCount = 16)
      )

      val mem = Module(
        new memory.SinglePortRAM(
          rawMemCfg = rawMemCfg,
          portCfg = portCfg
        )
      )

      val bridge = Module(
        new memory.Axi4FullToReadWriteBridge(cfg = axiMasterCfg)
      )

      bridge.read.req :=> mem.read.req
      mem.read.resp :=> bridge.read.resp

      bridge.write.req :=> mem.write.req
      mem.write.resp :=> bridge.write.resp

      master :=> bridge.s_axi
    }
  }

  def hdlinfoModule: hdlinfo.Module = {
    import hdlinfo._
    import io.circe.generic.auto._
    import scala.collection.mutable.ArrayBuffer

    val ports = ArrayBuffer.empty[Port]
    val interfaces = ArrayBuffer.empty[Interface]

    ports.append(
      Port(
        "clock",
        PortDirection.input,
        PortKind.clock,
        PortSensitivity.clockRising,
        associatedReset = "reset"
      )
    )
    ports.append(
      Port(
        "reset",
        PortDirection.input,
        PortKind.reset,
        PortSensitivity.resetActiveHigh,
        associatedClock = "clock"
      )
    )

    interfaces.append(
      Interface(
        "S_AXI_CTRL",
        InterfaceRole.slave,
        InterfaceKind("axi4_rtl"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("config" -> TypedObject(readEngineMultiCfg.axiCtrlCfg))
      )
    )

    interfaces.append(
      Interface(
        "S_AXI_DESC",
        InterfaceRole.slave,
        InterfaceKind("axi4_rtl"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("config" -> TypedObject(readEngineMultiCfg.axiDescCfg))
      )
    )

    Module(
      moduleName,
      ports.toSeq,
      interfaces.toSeq,
      Map("config" -> TypedObject(this))
    )
  }
}

object ReadEngineMul_tiSim1_TB extends chext.TestBench {
  emit(new ReadEngineMultiSim1)
}
