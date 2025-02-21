package chext.amba.axi4.full.components

import chisel3._
import chisel3.util._

import chext.amba.axi4
import axi4.Ops._

import chext.HasHdlinfoModule

class SctlmTest extends Module with HasHdlinfoModule {
  val axiSlaveCfg = axi4.Config(wId = 0, wAddr = 20, wData = 32)
  val axiMasterCfg = axiSlaveCfg.copy(wData = 256)

  val S_AXI = IO(axi4.Slave(axiSlaveCfg))
  val M_AXI = IO(axi4.Master(axiMasterCfg))

  private val protocolConverter = Module(
    new ProtocolConverter(ProtocolConverterConfig(axiSlaveCfg, axiMasterCfg))
  )

  S_AXI.asFull :=> protocolConverter.s_axi
  protocolConverter.m_axi :=> M_AXI.asFull

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
        "S_AXI",
        InterfaceRole.slave,
        InterfaceKind("axi4"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("config" -> TypedObject(axiSlaveCfg))
      )
    )

    interfaces.append(
      Interface(
        "M_AXI",
        InterfaceRole.master,
        InterfaceKind("axi4"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("config" -> TypedObject(axiMasterCfg))
      )
    )

    Module(
      "SctlmTest",
      ports.toSeq,
      interfaces.toSeq,
      Map()
    )
  }
}

object EmitSctlmTest extends chext.TestBench {
  emit(new SctlmTest)
}
