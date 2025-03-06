package chext.ip.float

import chisel3._
import chisel3.util._

import chext.elastic
import elastic.ConnectOp._

class ElasticTop extends Module with chext.HasHdlinfoModule {
  val genFp32 = FloatingPoint.ieee_fp32
  val genFp64 = FloatingPoint.ieee_fp64

  val fp32_inA = IO(elastic.Source(UInt(32.W)))
  val fp32_inB = IO(elastic.Source(UInt(32.W)))
  val fp32_addOut = IO(elastic.Sink(UInt(32.W)))
  val fp32_multiplyOut = IO(elastic.Sink(UInt(32.W)))

  val fp64_inA = IO(elastic.Source(UInt(64.W)))
  val fp64_inB = IO(elastic.Source(UInt(64.W)))
  val fp64_addOut = IO(elastic.Sink(UInt(64.W)))
  val fp64_multiplyOut = IO(elastic.Sink(UInt(64.W)))

  private val fp32_add = Module(new ElasticAdd(genFp32))
  private val fp64_add = Module(new ElasticAdd(genFp64))

  private val fp32_multiply = Module(new ElasticMultiply(genFp32))
  private val fp64_multiply = Module(new ElasticMultiply(genFp64))

  new elastic.Transform(fp32_add.sinkOut, elastic.SinkBuffer(fp32_addOut, 32)) {
    protected def onTransform: Unit = {
      out := in.asUInt
    }
  }

  new elastic.Transform(fp64_add.sinkOut, elastic.SinkBuffer(fp64_addOut, 32)) {
    protected def onTransform: Unit = {
      out := in.asUInt
    }
  }

  new elastic.Transform(fp32_multiply.sinkOut, elastic.SinkBuffer(fp32_multiplyOut, 32)) {
    protected def onTransform: Unit = {
      out := in.asUInt
    }
  }

  new elastic.Transform(fp64_multiply.sinkOut, elastic.SinkBuffer(fp64_multiplyOut, 32)) {
    protected def onTransform: Unit = {
      out := in.asUInt
    }
  }

  private val fork0 = new elastic.Fork(elastic.SourceBuffer(fp32_inA, 32)) {
    protected def onFork: Unit = {
      fork { in.asTypeOf(genFp32) } :=> fp32_add.sourceInA
      fork { in.asTypeOf(genFp32) } :=> fp32_multiply.sourceInA
    }
  }

  private val fork1 = new elastic.Fork(elastic.SourceBuffer(fp32_inB, 32)) {
    protected def onFork: Unit = {
      fork { in.asTypeOf(genFp32) } :=> fp32_add.sourceInB
      fork { in.asTypeOf(genFp32) } :=> fp32_multiply.sourceInB
    }
  }

  private val fork2 = new elastic.Fork(elastic.SourceBuffer(fp64_inA, 32)) {
    protected def onFork: Unit = {
      fork { in.asTypeOf(genFp64) } :=> fp64_add.sourceInA
      fork { in.asTypeOf(genFp64) } :=> fp64_multiply.sourceInA
    }
  }

  private val fork3 = new elastic.Fork(elastic.SourceBuffer(fp64_inB, 32)) {
    protected def onFork: Unit = {
      fork { in.asTypeOf(genFp64) } :=> fp64_add.sourceInB
      fork { in.asTypeOf(genFp64) } :=> fp64_multiply.sourceInB
    }
  }

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
        "fp32_inA",
        InterfaceRole("source"),
        InterfaceKind(f"readyValid[chext.elastic.Data]"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("width" -> TypedObject(32))
      ),
      Interface(
        "fp32_inB",
        InterfaceRole("source"),
        InterfaceKind(f"readyValid[chext.elastic.Data]"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("width" -> TypedObject(32))
      ),
      Interface(
        "fp32_addOut",
        InterfaceRole("sink"),
        InterfaceKind(f"readyValid[chext.elastic.Data]"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("width" -> TypedObject(32))
      ),
      Interface(
        "fp32_multiplyOut",
        InterfaceRole("sink"),
        InterfaceKind(f"readyValid[chext.elastic.Data]"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("width" -> TypedObject(32))
      ),
      Interface(
        "fp64_inA",
        InterfaceRole("source"),
        InterfaceKind(f"readyValid[chext.elastic.Data]"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("width" -> TypedObject(64))
      ),
      Interface(
        "fp64_inB",
        InterfaceRole("source"),
        InterfaceKind(f"readyValid[chext.elastic.Data]"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("width" -> TypedObject(64))
      ),
      Interface(
        "fp64_addOut",
        InterfaceRole("sink"),
        InterfaceKind(f"readyValid[chext.elastic.Data]"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("width" -> TypedObject(64))
      ),
      Interface(
        "fp64_multiplyOut",
        InterfaceRole("sink"),
        InterfaceKind(f"readyValid[chext.elastic.Data]"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("width" -> TypedObject(64))
      )
    )
    val args = Map.empty[String, TypedObject]

    Module(desiredName, ports, interfaces, args)
  }
}

object ElasticTop_TB extends chext.TestBench {
  emit(new ElasticTop())
}
