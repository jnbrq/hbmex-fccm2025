package hbmex.components.spmv

import chisel3._
import chisel3.util._

import chext.elastic
import elastic.ConnectOp._

class RowReduceSingleTop(override val desiredName: String = "RowReduceSingleTop") extends Module with chext.HasHdlinfoModule {
  private val dut = Module(new RowReduceSingle)
  private val batchAdd = Module(new BatchAdd)

  val sourceElem = IO(elastic.Source(chiselTypeOf(dut.sourceElem.bits)))
  val sinkResult = IO(elastic.Sink(chiselTypeOf(dut.sinkResult.bits)))

  dut.batchAddReq :=> batchAdd.req
  batchAdd.resp :=> dut.batchAddResp

  sourceElem :=> dut.sourceElem
  dut.sinkResult :=> sinkResult

  def hdlinfoModule: hdlinfo.Module = {
    import hdlinfo._
    import io.circe.generic.auto._

    val ports = Seq(
      Port(
        "clock",
        PortDirection.input,
        PortKind.clock,
        PortSensitivity.clockRising,
        associatedReset = "reset"
      ),
      Port(
        "reset",
        PortDirection.input,
        PortKind.reset,
        PortSensitivity.resetActiveHigh,
        associatedClock = "clock"
      )
    )

    val interfaces = Seq(
      Interface(
        "sourceElem",
        InterfaceRole("source"),
        InterfaceKind(f"readyValid[chext.elastic.DataLast]"),
        associatedClock = "clock",
        associatedReset = "reset",

        // HARDCODED
        args = Map("width" -> TypedObject(256))
      ),
      Interface(
        "sinkResult",
        InterfaceRole("sink"),
        InterfaceKind(f"readyValid[chext.elastic.Data]"),
        associatedClock = "clock",
        associatedReset = "reset",

        // HARDCODED
        args = Map("width" -> TypedObject(256))
      )
    )

    val args = Map.empty[String, TypedObject]

    Module(desiredName, ports, interfaces, args)
  }
}

class RowReduceTop(override val desiredName: String = "RowReduceTop") extends Module with chext.HasHdlinfoModule {
  private val dut = Module(new RowReduce)
  chext.exportIO.module(this, dut)

  def hdlinfoModule: hdlinfo.Module = {
    import hdlinfo._
    import io.circe.generic.auto._

    val ports = Seq(
      Port(
        "clock",
        PortDirection.input,
        PortKind.clock,
        PortSensitivity.clockRising,
        associatedReset = "reset"
      ),
      Port(
        "reset",
        PortDirection.input,
        PortKind.reset,
        PortSensitivity.resetActiveHigh,
        associatedClock = "clock"
      )
    )

    val interfaces = Seq(
      Interface(
        "sourceElem",
        InterfaceRole("source"),
        InterfaceKind(f"readyValid[chext.elastic.Data]"),
        associatedClock = "clock",
        associatedReset = "reset",

        // HARDCODED
        args = Map("width" -> TypedObject(256))
      ),
      Interface(
        "sourceCount",
        InterfaceRole("source"),
        InterfaceKind(f"readyValid[chext.elastic.Data]"),
        associatedClock = "clock",
        associatedReset = "reset",

        // HARDCODED
        args = Map("width" -> TypedObject(32))
      ),
      Interface(
        "sinkResult",
        InterfaceRole("sink"),
        InterfaceKind(f"readyValid[chext.elastic.Data]"),
        associatedClock = "clock",
        associatedReset = "reset",

        // HARDCODED
        args = Map("width" -> TypedObject(256))
      )
    )

    val args = Map.empty[String, TypedObject]

    Module(desiredName, ports, interfaces, args)
  }
}

object RowReduceTestBench extends chext.TestBench {
  emit(new RowReduceSingleTop)
  emit(new RowReduceTop)
}
