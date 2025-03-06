package hbmex.components.stream

import chisel3._
import chisel3.util._

import chext.elastic
import elastic.ConnectOp._

import chext.amba.axi4
import axi4.Ops._

import chext.{HasHdlinfoModule, TestBench}

private class AxiTestSlave(axiCfg: axi4.Config) extends Module {
  val s_axi = IO(axi4.full.Slave(axiCfg))

  require(isPow2(axiCfg.wAddr))
  require(isPow2(axiCfg.wData))
  require(axiCfg.wAddr <= axiCfg.wData)

  private val log2wAddr = log2Ceil(axiCfg.wAddr)
  private val log2wData = log2Ceil(axiCfg.wData)

  private def mkData(addr: UInt, index: UInt): UInt = {
    val index0 = addr + (index << (log2wData - log2wAddr))

    Cat(
      (0 until (1 << (log2wData - log2wAddr))) //
        .map { case i: Int => (index0 + i.U) } //
        .reverse
    )
  }

  new elastic.Replicate(s_axi.ar, elastic.SinkBuffer(s_axi.r)) {
    protected def onReplicate: Unit = {
      len := in.len +& 1.U

      out := 0.U.asTypeOf(out)

      out.last := last
      out.data := mkData(in.addr, idx)
    }
  }

  if (axiCfg.write) {
    s_axi.aw.nodeq()
    s_axi.w.nodeq()
    s_axi.b.noenq()
  }
}

class ReadStreamTop1(
    val cfg: ReadStreamConfig,
    override val desiredName: String
) extends Module
    with HasHdlinfoModule {
  private val dut = Module(new ReadStream(cfg))
  private val axiTestSlave = Module(new AxiTestSlave(cfg.axiMasterCfg))

  val sourceTask = IO(chiselTypeOf(dut.sourceTask))
  val sinkData = IO(chiselTypeOf(dut.sinkData))

  sourceTask :=> dut.sourceTask
  dut.sinkData :=> sinkData

  dut.m_axi :=> axiTestSlave.s_axi

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
        "sourceTask",
        InterfaceRole("source"),
        InterfaceKind(f"readyValid[ReadStreamTask]"),
        associatedClock = "clock",
        associatedReset = "reset"
      ),
      Interface(
        "sinkData",
        InterfaceRole("sink"),
        InterfaceKind(f"readyValid[chext.elastic.Data]"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("width" -> TypedObject(cfg.wDataSink))
      )
    )
    val args = Map(
      "cfg" -> TypedObject(cfg)
    )

    Module(desiredName, ports, interfaces, args)
  }
}

class ReadStreamTop2(
    val cfg: ReadStreamConfig,
    val wDataSink: Int,
    override val desiredName: String
) extends Module
    with HasHdlinfoModule {

  private val readStream = Module(
    new ReadStreamWithLast(cfg)
  )

  private val downsize = Module(
    new DownsizeWithLast(DownsizeConfig(cfg.wDataSink, wDataSink))
  )

  private val axiTestSlave = Module(new AxiTestSlave(cfg.axiMasterCfg))

  val sourceTask = IO(chiselTypeOf(readStream.sourceTask))
  val sinkData = IO(chiselTypeOf(downsize.sink))

  sourceTask :=> readStream.sourceTask
  readStream.sinkData :=> downsize.source
  downsize.sink :=> sinkData

  readStream.m_axi :=> axiTestSlave.s_axi

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
        "sourceTask",
        InterfaceRole("source"),
        InterfaceKind(f"readyValid[ReadStreamTask]"),
        associatedClock = "clock",
        associatedReset = "reset"
      ),
      Interface(
        "sinkData",
        InterfaceRole("sink"),
        InterfaceKind(f"readyValid[chext.elastic.DataLast]"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("width" -> TypedObject(wDataSink))
      )
    )
    val args = Map(
      "cfg" -> TypedObject(cfg)
    )

    Module(desiredName, ports, interfaces, args)
  }
}

object ReadStream_TB extends chext.TestBench {
  emit(
    new ReadStreamTop1(
      ReadStreamConfig(axi4.Config(wAddr = 32, wData = 64)),
      "ReadStreamTop1_1"
    )
  )

  emit(
    new ReadStreamTop2(
      ReadStreamConfig(axi4.Config(wAddr = 32, wData = 128)),
      32,
      "ReadStreamTop2_1"
    )
  )
}
