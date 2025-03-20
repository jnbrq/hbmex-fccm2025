package chext.sysc_tb

import chisel3._
import scala.collection.mutable.ArrayBuffer

object _emitHdlinfo {
  def apply(module: hdlinfo.Module, targetDir: String): Unit = {
    import io.circe.syntax._
    import io.circe.generic.auto._
    import java.io.PrintWriter

    val pw = new PrintWriter(f"${targetDir}/${module.name}.hdlinfo.json")
    pw.write(module.asJson.toString())
    pw.close()
  }
}

object EmitAddressGenerator extends App {
  val wAddr = 32

  val hdlinfoModule = {
    import hdlinfo._

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
        InterfaceKind("readyValid[chext.amba.axi4.full.components.addrgen.AddrSizeLastBundle]"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("wAddr" -> TypedObject(wAddr))
      )
    )

    Module(
      "AddressGenerator",
      ports.toSeq,
      interfaces.toSeq,
      Map("wAddr" -> TypedObject(wAddr))
    )
  }

  emitVerilog(new chext.amba.axi4.full.components.AddressGenerator(wAddr))
  _emitHdlinfo(hdlinfoModule, "./")
}

object EmitAddressStrobeGenerator extends App {
  val wAddr = 32
  val wData = 128

  val hdlinfoModule = {
    import hdlinfo._

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
        InterfaceKind("readyValid[chext.amba.axi4.full.components.addrgen.AddrSizeStrobeLastBundle]"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("wAddr" -> TypedObject(wAddr), "wData" -> TypedObject(wData))
      )
    )

    Module(
      "AddressStrobeGenerator",
      ports.toSeq,
      interfaces.toSeq,
      Map("wAddr" -> TypedObject(wAddr), "wData" -> TypedObject(wData))
    )
  }

  emitVerilog(new chext.amba.axi4.full.components.AddressStrobeGenerator(wAddr, wData))
  _emitHdlinfo(hdlinfoModule, "./")
}
