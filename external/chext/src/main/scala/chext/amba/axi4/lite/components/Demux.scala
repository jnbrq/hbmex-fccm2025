package chext.amba.axi4.lite.components

import chext.amba.axi4
import chext.elastic
import chext.bundles

import chisel3._
import chisel3.util._
import chisel3.experimental._

import elastic._
import elastic.TransformOp._
import elastic.ConnectOp._

import axi4.Casts._
import axi4.lite.{SlaveBuffer, MasterBuffer}

import chext.bundles._

case class DemuxConfig(
    val axiSlaveCfg: axi4.Config,
    val numMasters: Int = 4,
    val decodeFn: (UInt) => (UInt),
    val capacityPortQueueR: Int = 8,
    val capacityPortQueueW: Int = 8,
    val capacityPortQueueB: Int = 8,
    val slaveBuffers: axi4.BufferConfig = axi4.BufferConfig.all(2),
    val masterBuffers: axi4.BufferConfig = axi4.BufferConfig.all(0)
) {
  require(axiSlaveCfg.lite, "should use AXI4 lite")
  require(axiSlaveCfg.read || axiSlaveCfg.write, "must be at least read or write")
  require(numMasters > 0, "number of masters must be positive")

  require(capacityPortQueueR > 0)
  require(capacityPortQueueW > 0)
  require(capacityPortQueueB > 0)

  val wPort = log2Up(numMasters)

  val axiMasterCfg = axiSlaveCfg
}

class Demux(val cfg: DemuxConfig) extends Module {
  import cfg._

  override def desiredName: String = "axi4LiteDemux"

  val s_axil = IO(axi4.lite.Slave(axiSlaveCfg))
  val m_axil = IO(Vec(numMasters, axi4.lite.Master(axiMasterCfg)))

  private val genPort = UInt(wPort.W)

  private val s_axil_ = SlaveBuffer(s_axil, slaveBuffers)
  private val m_axil_ = m_axil.map { (x) =>
    MasterBuffer(x, masterBuffers)
  }

  private def implRead(): Unit = prefix("read") {
    val portQueue = Module(
      new Queue(
        genPort,
        capacityPortQueueR,
        flow = true,
        pipe = true
      )
    )

    def arLogic: Unit = {
      val genArPort = new Bundle2(s_axil_.ar.bits.cloneType, genPort)
      val arPort = Wire(Irrevocable(genArPort))

      s_axil_.ar
        .transform(genArPort) {
          case (source, sink) => {
            sink._1 := source
            sink._2 := decodeFn(source.addr)
          }
        } :=> arPort

      val demuxInput = Wire(Irrevocable(s_axil_.ar.bits.cloneType))
      val demuxSelect = Wire(Irrevocable(genPort))

      new Fork(arPort) {
        protected def onFork: Unit = {
          fork(in._1) :=> demuxInput
          fork(in._2) :=> demuxSelect
          fork(in._2) :=> portQueue.io.enq
        }
      }

      chext.elastic.Demux(demuxInput, m_axil_.map(_.ar), demuxSelect)
    }

    def rLogic: Unit = {
      chext.elastic.Mux(m_axil_.map { _.r }, s_axil_.r, portQueue.io.deq)
    }

    arLogic
    rLogic
  }

  private def implWrite(): Unit = prefix("write") {
    val portQueueW = Module(
      new Queue(
        genPort,
        capacityPortQueueW,
        flow = true,
        pipe = true
      )
    )

    val portQueueB = Module(
      new Queue(
        genPort,
        capacityPortQueueB,
        flow = true,
        pipe = true
      )
    )

    def awLogic: Unit = {
      val genAwPort = new Bundle2(s_axil_.aw.bits.cloneType, genPort)
      val awPort = Wire(Irrevocable(genAwPort))

      s_axil_.aw
        .transform(genAwPort) {
          case (source, sink) => {
            sink._1 := source
            sink._2 := decodeFn(source.addr)
          }
        } :=> awPort

      val demuxAwInput = Wire(Irrevocable(s_axil_.aw.bits.cloneType))
      val demuxAwSelect = Wire(Irrevocable(genPort))

      new Fork(awPort) {
        protected def onFork: Unit = {
          fork(in._1) :=> demuxAwInput

          fork(in._2) :=> demuxAwSelect
          fork(in._2) :=> portQueueW.io.enq
          fork(in._2) :=> portQueueB.io.enq
        }
      }

      chext.elastic.Demux(demuxAwInput, m_axil_.map { _.aw }, demuxAwSelect)
    }

    def wLogic: Unit = {
      chext.elastic.Demux(s_axil_.w, m_axil_.map { _.w }, portQueueW.io.deq)
    }

    def bLogic: Unit = {
      chext.elastic.Mux(m_axil_.map { _.b }, s_axil_.b, portQueueB.io.deq)
    }

    awLogic
    wLogic
    bLogic
  }

  if (axiSlaveCfg.read) implRead()
  if (axiSlaveCfg.write) implWrite()
}
