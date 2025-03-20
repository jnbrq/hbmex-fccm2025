package chext.amba.axi4.full.components

import chisel3._
import chisel3.util._

import chext.amba.axi4
import chext.elastic
import chext.ip.memory

import axi4.Ops._
import elastic.ConnectOp._

case class DownscaleTestTop1(
    val wDataWide: Int,
    val wDataNarrow: Int,
    override val desiredName: String
) extends Module
    with chext.HasHdlinfoModule {
  val log2bytesTotal = 14

  val rawMemCfg = memory.RawMemConfig(log2bytesTotal - log2Ceil(wDataNarrow / 8), wDataNarrow, 4, 4)
  val portCfg = memory.PortConfig(8, 8)

  val axiCfgWide = axi4.Config(0, log2bytesTotal, wDataWide)
  val axiCfgNarrow = axi4.Config(0, log2bytesTotal, wDataNarrow)

  val S_AXI_NORMAL = IO(axi4.Slave(axiCfgNarrow))
  val S_AXI_TEST = IO(axi4.Slave(axiCfgWide))

  private val mem = Module(
    new memory.TrueDualPortRAM(rawMemCfg, portCfg, portCfg)
  )

  private val axiBridge1 = Module(new memory.Axi4FullToReadWriteBridge(axiCfgNarrow))

  S_AXI_NORMAL :=> axiBridge1.s_axi

  axiBridge1.read.req :=> mem.read1.req
  mem.read1.resp :=> axiBridge1.read.resp

  axiBridge1.write.req :=> mem.write1.req
  mem.write1.resp :=> axiBridge1.write.resp

  private val axiBridge2 = Module(new memory.Axi4FullToReadWriteBridge(axiCfgNarrow))

  axiBridge2.read.req :=> mem.read2.req
  mem.read2.resp :=> axiBridge2.read.resp

  axiBridge2.write.req :=> mem.write2.req
  mem.write2.resp :=> axiBridge2.write.resp

  private val unburstCfg = UnburstConfig(axiCfgWide, 8, 8)
  private val unburst = Module(new Unburst(unburstCfg))

  private val downscaleCfg = DownscaleConfig(axiCfgWide, wDataNarrow)
  private val downscale = Module(new Downscale(downscaleCfg))

  S_AXI_TEST :=> unburst.s_axi
  unburst.m_axi :=> downscale.s_axi
  downscale.m_axi :=> axiBridge2.s_axi

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
        args = Map("config" -> TypedObject(axiCfgNarrow))
      )
    )
    interfaces.append(
      Interface(
        "S_AXI_TEST",
        InterfaceRole.slave,
        InterfaceKind("axi4"),
        associatedClock = "clock",
        associatedReset = "reset",
        args = Map("config" -> TypedObject(axiCfgWide))
      )
    )

    Module(
      desiredName,
      ports.toSeq,
      interfaces.toSeq,
      Map(
        "wDataWide" -> TypedObject(wDataWide),
        "wDataNarrow" -> TypedObject(wDataNarrow)
      )
    )
  }
}

object Downscale_TB extends chext.TestBench {
  emit(new DownscaleTestTop1(128, 32, "DownscaleTestTop1_1"))
  emit(new DownscaleTestTop1(128, 64, "DownscaleTestTop1_2"))
}
