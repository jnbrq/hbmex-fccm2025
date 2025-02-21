package chext.amba.axi4.full.components

import chisel3._
import chisel3.util._

import chext.amba.axi4
import chext.elastic
import chext.ip.memory

import axi4.Ops._
import elastic.ConnectOp._

class IdParallelizeNoReadBurstTestTop1(override val desiredName: String) extends Module with chext.HasHdlinfoModule {
  val log2bytesTotal = 14
  val wData = 128

  val rawMemCfg = memory.RawMemConfig(log2bytesTotal - log2Ceil(wData / 8), wData, 4, 4)
  val portCfg = memory.PortConfig(8, 8)

  val axiCfg = axi4.Config(4, log2bytesTotal, wData)

  val S_AXI_NORMAL = IO(axi4.Slave(axiCfg))
  val S_AXI_TEST = IO(axi4.Slave(axiCfg.copy(wId = 0)))

  private val mem = Module(
    new memory.TrueDualPortRAM(rawMemCfg, portCfg, portCfg)
  )

  private val axiBridge1 = Module(new memory.Axi4FullToReadWriteBridge(axiCfg))

  S_AXI_NORMAL :=> axiBridge1.s_axi

  axiBridge1.read.req :=> mem.read1.req
  mem.read1.resp :=> axiBridge1.read.resp

  axiBridge1.write.req :=> mem.write1.req
  mem.write1.resp :=> axiBridge1.write.resp

  private val axiBridge2 = Module(new memory.Axi4FullToReadWriteBridge(axiCfg))

  axiBridge2.read.req :=> mem.read2.req
  mem.read2.resp :=> axiBridge2.read.resp

  axiBridge2.write.req :=> mem.write2.req
  mem.write2.resp :=> axiBridge2.write.resp

  private val IdParallelizeNoReadBurstCfg = IdParallelizeNoReadBurstConfig(axiCfg.copy(wId = 0), 4)
  private val IdParallelizeNoReadBurst = Module(new IdParallelizeNoReadBurst(IdParallelizeNoReadBurstCfg))
  S_AXI_TEST :=> IdParallelizeNoReadBurst.s_axi
  IdParallelizeNoReadBurst.m_axi :=> axiBridge2.s_axi

  override def hdlinfoModule: hdlinfo.Module = {
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
        "S_AXI_NORMAL",
        InterfaceRole.slave,
        InterfaceKind("axi4"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("config" -> TypedObject(axiCfg))
      )
    )

    interfaces.append(
      Interface(
        "S_AXI_TEST",
        InterfaceRole.slave,
        InterfaceKind("axi4"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("config" -> TypedObject(axiCfg))
      )
    )

    Module(
      desiredName,
      ports.toSeq,
      interfaces.toSeq,
      Map()
    )
  }
}

class IdParallelizeNoReadBurstTestTop2(
    val wId: Int,
    val readUseSyncMem: Boolean = true,
    val writeUseSyncMem: Boolean = true,
    override val desiredName: String
) extends Module
    with chext.HasHdlinfoModule {

  private val cfg = IdParallelizeNoReadBurstConfig(
    axi4.Config(wId = 0, wAddr = 32, wData = 64, wUserB = 32 /* for testing purposes */ ),
    wId,
    readUseSyncMem,
    writeUseSyncMem
  )
  private val dut = Module(new IdParallelizeNoReadBurst(cfg))

  val S_AXI = IO(axi4.Slave(cfg.axiSlaveCfg))
  val M_AXI = IO(axi4.Master(cfg.axiMasterCfg))

  S_AXI.asFull :=> dut.s_axi
  dut.m_axi :=> M_AXI.asFull

  override def hdlinfoModule: hdlinfo.Module = {
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
        "S_AXI",
        InterfaceRole.slave,
        InterfaceKind("axi4"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("config" -> TypedObject(cfg.axiSlaveCfg))
      )
    )

    interfaces.append(
      Interface(
        "M_AXI",
        InterfaceRole.master,
        InterfaceKind("axi4"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("config" -> TypedObject(cfg.axiMasterCfg))
      )
    )

    Module(
      desiredName,
      ports.toSeq,
      interfaces.toSeq,
      Map()
    )
  }
}

object IdParallelizeNoReadBurst_TB extends chext.TestBench {
  emit(new IdParallelizeNoReadBurstTestTop1("IdParallelizeNoReadBurstTestTop1_1"))

  emit(new IdParallelizeNoReadBurstTestTop2(2, true, true, "IdParallelizeNoReadBurstTestTop2_1"))
  emit(new IdParallelizeNoReadBurstTestTop2(3, true, true, "IdParallelizeNoReadBurstTestTop2_2"))
  emit(new IdParallelizeNoReadBurstTestTop2(6, true, true, "IdParallelizeNoReadBurstTestTop2_3"))

  emit(new IdParallelizeNoReadBurstTestTop2(2, false, false, "IdParallelizeNoReadBurstTestTop2_4"))
  emit(new IdParallelizeNoReadBurstTestTop2(3, false, false, "IdParallelizeNoReadBurstTestTop2_5"))
  emit(new IdParallelizeNoReadBurstTestTop2(6, false, false, "IdParallelizeNoReadBurstTestTop2_6"))
}
