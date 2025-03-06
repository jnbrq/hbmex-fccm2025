package hbmex.components.spmv

import chisel3._
import chisel3.util._

import chext.elastic
import elastic.ConnectOp._

import chext.amba.axi4
import axi4.Ops._

import hbmex.components.stream

case class SpmvTop1Config(val desiredName: String) {
  val wAddr = 30
  val wData = 256
  val wId = 8

  val wSourceTask = 7 * Defs.wPointer
  val wSinkDone = Defs.wTime

  val axiSlaveCfg = axi4.Config(
    wId = 0,
    wAddr = wAddr,
    wData = wData,
    axi3Compat = true,
    hasQos = false,
    hasProt = false,
    hasCache = false,
    hasRegion = false,
    hasLock = false
  )

  val axiMemCfg = axiSlaveCfg.copy(wId = wId + 2)

  val spmvCfg = SpmvConfig(wAddr)

  val muxCfg = axi4.full.components.MuxConfig(
    axiSlaveCfg.copy(wId = wId),
    3
  )
}

/** Uses the elastic task interface for testing.
  *
  * @param cfg
  */
class SpmvTop1(cfg: SpmvTop1Config) extends Module with chext.HasHdlinfoModule {
  import cfg._
  override val desiredName = cfg.desiredName

  private val spmv0 = Module(new Spmv(spmvCfg))

  val s_axi = IO(axi4.Slave(axiSlaveCfg))
  val sourceTask = IO(elastic.Source(UInt(wSourceTask.W)))
  val sinkDone = IO(elastic.Sink(UInt(wSinkDone.W)))

  private val s_axi_mem = {
    import chext.ip.memory._

    val latencyRead: Int = 1
    val latencyWrite: Int = 1

    val rawMemCfg = RawMemConfig(
      wAddr = axiMemCfg.wAddr - (log2Ceil(axiMemCfg.wData) - 3),
      wData = axiMemCfg.wData,
      latencyRead = latencyRead,
      latencyWrite = latencyWrite
    )

    val portCfg = PortConfig(
      numOutstandingRead = 4,
      numOutstandingWrite = 4
    )

    val mem = Module(
      new TrueDualPortRAM(
        rawMemCfg,
        portCfg.copy(arbiterFunc = () => new ReadOnlyArbiter),
        portCfg.copy(arbiterFunc = () => new WriteOnlyArbiter)
      )
    )

    val bridge = Module(new Axi4FullToReadWriteBridge(axiMemCfg))

    bridge.read.req :=> mem.read1.req
    mem.read1.resp :=> bridge.read.resp

    mem.write1.req.noenq()
    mem.write1.resp.nodeq()

    bridge.write.req :=> mem.write2.req
    mem.write2.resp :=> bridge.write.resp

    mem.read2.req.noenq()
    mem.read2.resp.nodeq()

    bridge.s_axi
  }

  private val mux = Module(new axi4.full.components.Mux(muxCfg))
  mux.m_axi :=> s_axi_mem

  s_axi.asFull :=> mux.s_axi(0)

  spmv0.m_axi_regular :=> mux.s_axi(1)
  spmv0.m_axi_random :=> mux.s_axi(2)

  new elastic.Transform(sourceTask, spmv0.sourceTask) {
    protected def onTransform: Unit = {
      out := in.asTypeOf(out)
    }
  }

  new elastic.Transform(spmv0.sinkDone, sinkDone) {
    protected def onTransform: Unit = {
      out := in.asTypeOf(out)
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
        "s_axi",
        InterfaceRole("slave"),
        InterfaceKind(f"axi4"),
        associatedClock = "clock",
        associatedReset = "reset",

        // HARDCODED
        args = Map("config" -> TypedObject(axiSlaveCfg))
      ),
      Interface(
        "sourceTask",
        InterfaceRole("source"),
        InterfaceKind(f"readyValid[chext.elastic.Data]"),
        associatedClock = "clock",
        associatedReset = "reset",

        // HARDCODED
        args = Map("width" -> TypedObject(wSourceTask))
      ),
      Interface(
        "sinkDone",
        InterfaceRole("sink"),
        InterfaceKind(f"readyValid[chext.elastic.Data]"),
        associatedClock = "clock",
        associatedReset = "reset",

        // HARDCODED
        args = Map("width" -> TypedObject(wSinkDone))
      )
    )

    val args = Map.empty[String, TypedObject]

    Module(desiredName, ports, interfaces, args)
  }
}

case class SpmvTop2Config(val desiredName: String = "SpmvTop2_1") {
  val wAddr = 30
  val wData = 256
  val wId = 8

  val axiControlCfg = axi4.Config(wAddr = 10, wData = 32, lite = true)

  val axiSlaveCfg = axi4.Config(
    wId = 0,
    wAddr = wAddr,
    wData = wData,
    axi3Compat = true,
    hasQos = false,
    hasProt = false,
    hasCache = false,
    hasRegion = false,
    hasLock = false
  )

  val axiMemCfg = axiSlaveCfg.copy(wId = wId + 2)

  val spmvCfg = SpmvConfig(wAddr)
  val memAdapterCfg = stream.MemAdapterConfig(Defs.wTime, Defs.wTask, 10)

  val muxCfg = axi4.full.components.MuxConfig(
    axiSlaveCfg.copy(wId = wId),
    3
  )
}

/** Uses an AXI4-Lite interface for sending tasks.
  *
  * @param cfg
  */
class SpmvTop2(cfg: SpmvTop2Config = SpmvTop2Config()) extends Module with chext.HasHdlinfoModule {
  import cfg._
  override val desiredName = cfg.desiredName

  private val spmv0 = Module(new Spmv(spmvCfg))
  private val memAdapter0 = Module(new stream.MemAdapter(memAdapterCfg))

  val s_axi_control = IO(axi4.Slave(axiControlCfg))
  val s_axi = IO(axi4.Slave(axiSlaveCfg))

  private val s_axi_mem = {
    import chext.ip.memory._

    val latencyRead: Int = 1
    val latencyWrite: Int = 1

    val rawMemCfg = RawMemConfig(
      wAddr = axiMemCfg.wAddr - (log2Ceil(axiMemCfg.wData) - 3),
      wData = axiMemCfg.wData,
      latencyRead = latencyRead,
      latencyWrite = latencyWrite
    )

    val portCfg = PortConfig(
      numOutstandingRead = 4,
      numOutstandingWrite = 4
    )

    val mem = Module(
      new TrueDualPortRAM(
        rawMemCfg,
        portCfg.copy(arbiterFunc = () => new ReadOnlyArbiter),
        portCfg.copy(arbiterFunc = () => new WriteOnlyArbiter)
      )
    )

    val bridge = Module(new Axi4FullToReadWriteBridge(axiMemCfg))

    bridge.read.req :=> mem.read1.req
    mem.read1.resp :=> bridge.read.resp

    mem.write1.req.noenq()
    mem.write1.resp.nodeq()

    bridge.write.req :=> mem.write2.req
    mem.write2.resp :=> bridge.write.resp

    mem.read2.req.noenq()
    mem.read2.resp.nodeq()

    bridge.s_axi
  }

  private val mux = Module(new axi4.full.components.Mux(muxCfg))
  mux.m_axi :=> s_axi_mem

  s_axi.asFull :=> mux.s_axi(0)

  spmv0.m_axi_regular :=> mux.s_axi(1)
  spmv0.m_axi_random :=> mux.s_axi(2)

  s_axi_control :=> memAdapter0.s_axil

  new elastic.Transform(elastic.SourceBuffer(memAdapter0.sink, 4), spmv0.sourceTask) {
    protected def onTransform: Unit = {
      out := in.asTypeOf(out)
    }
  }

  new elastic.Transform(spmv0.sinkDone, elastic.SinkBuffer(memAdapter0.source, 4)) {
    protected def onTransform: Unit = {
      out := in.asUInt
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
        "s_axi_control",
        InterfaceRole("slave"),
        InterfaceKind(f"axi4"),
        associatedClock = "clock",
        associatedReset = "reset",

        // HARDCODED
        args = Map("config" -> TypedObject(axiControlCfg))
      ),
      Interface(
        "s_axi",
        InterfaceRole("slave"),
        InterfaceKind(f"axi4"),
        associatedClock = "clock",
        associatedReset = "reset",

        // HARDCODED
        args = Map("config" -> TypedObject(axiSlaveCfg))
      )
    )

    val args = Map.empty[String, TypedObject]

    Module(desiredName, ports, interfaces, args)
  }
}

object Spmv_TB extends chext.TestBench {
  emit(new SpmvTop1(SpmvTop1Config("SpmvTop1_1")))
  emit(new SpmvTop2(SpmvTop2Config("SpmvTop2_1")))
}
