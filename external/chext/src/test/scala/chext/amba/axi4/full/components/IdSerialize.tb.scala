package chext.amba.axi4.full.components

import chisel3._
import chisel3.util._

import chext.amba.axi4
import chext.elastic
import chext.ip.memory

import axi4.Ops._
import elastic.ConnectOp._

case class IdSerializeTestTop1(
    val wId: Int,
    override val desiredName: String
) extends Module
    with chext.HasHdlinfoModule {
  val log2bytesTotal = 14
  val wData = 64

  val rawMemCfg = memory.RawMemConfig(log2bytesTotal - log2Ceil(wData / 8), wData, 4, 4)
  val portCfg = memory.PortConfig(8, 8)

  val axiCfg = axi4.Config(wId, log2bytesTotal, wData)

  val S_AXI_NORMAL = IO(axi4.Slave(axiCfg))
  val S_AXI_TEST = IO(axi4.Slave(axiCfg))

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

  private val idSerializeCfg = IdSerializeConfig(axiCfg)
  private val idSerialize = Module(new IdSerialize(idSerializeCfg))
  S_AXI_TEST :=> idSerialize.s_axi
  idSerialize.m_axi :=> axiBridge2.s_axi

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
      Map(
        "wId" -> TypedObject(wId)
      )
    )
  }
}

object IdSerialize_TB extends chext.TestBench {
  emit(new IdSerializeTestTop1(4, "IdSerializeTestTop1_1"))
}
