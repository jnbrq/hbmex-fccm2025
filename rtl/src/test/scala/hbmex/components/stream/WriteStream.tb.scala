package hbmex.components.stream

import chisel3._
import chisel3.util._

import chext.elastic
import elastic.ConnectOp._

import chext.amba.axi4
import axi4.Ops._

import chext.{HasHdlinfoModule, TestBench}

class WriteStreamTop1(
    override val desiredName: String
) extends Module
    with HasHdlinfoModule {
  private val axiCfg = axi4.Config(wId = 0, wAddr = 20, wData = 32)

  private val readStreamCfg = ReadStreamConfig(axiCfg, queueLength = 8)
  private val writeStreamCfg = WriteStreamConfig(axiCfg, queueLengthB = 8, queueLengthW = 8)

  private val readStream = Module(new ReadStream(readStreamCfg))
  private val writeStream = Module(new WriteStream(writeStreamCfg))

  val sourceReadTask = IO(chiselTypeOf(readStream.sourceTask))
  val sinkReadData = IO(chiselTypeOf(readStream.sinkData))

  val sourceWriteTask = IO(chiselTypeOf(writeStream.sourceTask))
  val sourceWriteData = IO(chiselTypeOf(writeStream.sourceData))
  val sinkWriteDone = IO(elastic.Sink(UInt(8.W)))

  sourceReadTask :=> readStream.sourceTask
  readStream.sinkData :=> sinkReadData

  sourceWriteTask :=> writeStream.sourceTask
  sourceWriteData :=> writeStream.sourceData

  new elastic.Transform(writeStream.sinkDone, sinkWriteDone) {
    protected def onTransform: Unit = {
      out := 0.U
    }
  }

  private val (s_axi1, s_axi2) = {
    import chext.ip.memory._

    val rawMemCfg = RawMemConfig(axiCfg.wAddr - (log2Ceil(axiCfg.wData) - 3), axiCfg.wData, 1, 1)
    val portCfg = PortConfig(4, 4, () => new BasicReadWriteArbiter(8))

    val mem = Module(new TrueDualPortRAM(rawMemCfg, portCfg, portCfg))

    val axiBridge1 = Module(new Axi4FullToReadWriteBridge(axiCfg))
    val axiBridge2 = Module(new Axi4FullToReadWriteBridge(axiCfg))

    axiBridge1.read.req :=> mem.read1.req
    mem.read1.resp :=> axiBridge1.read.resp

    axiBridge1.write.req :=> mem.write1.req
    mem.write1.resp :=> axiBridge1.write.resp

    axiBridge2.read.req :=> mem.read2.req
    mem.read2.resp :=> axiBridge2.read.resp

    axiBridge2.write.req :=> mem.write2.req
    mem.write2.resp :=> axiBridge2.write.resp

    (axiBridge1.s_axi, axiBridge2.s_axi)
  }

  readStream.m_axi :=> s_axi1
  writeStream.m_axi :=> s_axi2

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
        "sourceReadTask",
        InterfaceRole("source"),
        InterfaceKind(f"readyValid[ReadStreamTask]"),
        associatedClock = "clock",
        associatedReset = "reset"
      ),
      Interface(
        "sinkReadData",
        InterfaceRole("sink"),
        InterfaceKind(f"readyValid[chext.elastic.Data]"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("width" -> TypedObject(readStreamCfg.wDataSink))
      ),
      Interface(
        "sourceWriteTask",
        InterfaceRole("source"),
        InterfaceKind(f"readyValid[WriteStreamTask]"),
        associatedClock = "clock",
        associatedReset = "reset"
      ),
      Interface(
        "sourceWriteData",
        InterfaceRole("source"),
        InterfaceKind(f"readyValid[chext.elastic.Data]"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("width" -> TypedObject(writeStreamCfg.wDataSource))
      ),
      Interface(
        "sinkWriteDone",
        InterfaceRole("sink"),
        InterfaceKind(f"readyValid[chext.elastic.Data]"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("width" -> TypedObject(8))
      )
    )

    val args = Map(
      "readStreamCfg" -> TypedObject(readStreamCfg),
      "writeStreamCfg" -> TypedObject(writeStreamCfg)
    )

    Module(desiredName, ports, interfaces, args)
  }
}

object WriteStream_TB extends chext.TestBench {
  emit(
    new WriteStreamTop1(
      "WriteStreamTop1_1"
    )
  )
}
