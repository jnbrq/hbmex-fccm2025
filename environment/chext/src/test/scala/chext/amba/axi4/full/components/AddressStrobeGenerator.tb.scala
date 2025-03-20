package chext.amba.axi4.full.components

import chisel3._
import chisel3.util._
import chisel3.reflect._

class AddressStrobeGeneratorTestTop1(
    val wAddr: Int,
    val wData: Int,
    override val desiredName: String
) extends Module
    with chext.HasHdlinfoModule {

  private val dut = Module(new AddressStrobeGenerator(wAddr, wData))
  chext.exportIO.module(this, dut)

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
        "source",
        InterfaceRole("source") /* TODO define InterfaceRole.source */,
        InterfaceKind("readyValid[chext.amba.axi4.full.components.addrgen.AddrLenSizeBurstBundle]"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("wAddr" -> TypedObject(wAddr))
      )
    )

    interfaces.append(
      Interface(
        "sink",
        InterfaceRole("sink"),
        InterfaceKind(
          "readyValid[chext.amba.axi4.full.components.addrgen.AddrSizeStrobeLastBundle]"
        ),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("wAddr" -> TypedObject(wAddr), "wData" -> TypedObject(wData))
      )
    )

    Module(
      desiredName,
      ports.toSeq,
      interfaces.toSeq,
      Map("wAddr" -> TypedObject(wAddr), "wData" -> TypedObject(wData))
    )
  }
}

object AddressStrobeGenerator_TB extends App with chext.TestBench {
  emit(new AddressStrobeGeneratorTestTop1(32, 128, "AddressStrobeGeneratorTestTop1_1"))
}
