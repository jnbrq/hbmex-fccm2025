package chext.amba.axi4.lite.components

import chext.amba.axi4
import chext.elastic

import chisel3._
import chisel3.util._
import chisel3.experimental._

import elastic._
import elastic.ConnectOp._

import axi4.Casts._
import axi4.lite.{SlaveBuffer, MasterBuffer}

case class MuxConfig(
    val axiSlaveCfg: axi4.Config,
    val numSlaves: Int = 4,
    val capacityPortQueueR: Int = 8,
    val capacityPortQueueW: Int = 8,
    val capacityPortQueueB: Int = 8,
    val slaveBuffers: axi4.BufferConfig = axi4.BufferConfig.all(0),
    val masterBuffers: axi4.BufferConfig = axi4.BufferConfig.all(2),
    val arbiterPolicy: Chooser.ChooserFn = Chooser.rr
) {
  require(axiSlaveCfg.lite, "should use AXI4 lite")
  require(axiSlaveCfg.read || axiSlaveCfg.write, "must be at least read or write")
  require(numSlaves > 0, "number of slaves must be positive")

  require(capacityPortQueueR > 0)
  require(capacityPortQueueW > 0)
  require(capacityPortQueueB > 0)

  val wPort = log2Up(numSlaves)

  val axiMasterCfg = axiSlaveCfg
}

class Mux(val cfg: MuxConfig) extends Module {
  import cfg._

  override def desiredName: String = "axi4LiteMux"

  val s_axil = IO(Vec(numSlaves, axi4.lite.Slave(axiSlaveCfg)))
  val m_axil = IO(axi4.lite.Master(axiMasterCfg))

  private val genPort = UInt(wPort.W)

  private val s_axil_ = s_axil.map { (x) =>
    SlaveBuffer(x, slaveBuffers)
  }
  private val m_axil_ = MasterBuffer(m_axil, masterBuffers)

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
      chext.elastic.BasicArbiter(
        s_axil_.map { _.ar },
        m_axil_.ar,
        arbiterPolicy,
        Some(portQueue.io.enq)
      )
    }

    def rLogic: Unit = {
      chext.elastic.Demux(m_axil_.r, s_axil_.map { _.r }, portQueue.io.deq)
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
      val arbiterSelect = Wire(Irrevocable(genPort))

      chext.elastic.BasicArbiter(
        s_axil_.map { _.aw },
        m_axil_.aw,
        arbiterPolicy,
        Some(arbiterSelect)
      )

      new Fork(arbiterSelect) {
        protected def onFork: Unit = {
          fork() :=> portQueueW.io.enq
          fork() :=> portQueueB.io.enq
        }
      }
    }

    def wLogic: Unit = {
      chext.elastic.Mux(s_axil_.map { _.w }, m_axil_.w, portQueueW.io.deq)
    }

    def bLogic: Unit = {
      chext.elastic.Demux(m_axil_.b, s_axil_.map { _.b }, portQueueB.io.deq)
    }

    awLogic
    wLogic
    bLogic
  }

  if (axiSlaveCfg.read) implRead()
  if (axiSlaveCfg.write) implWrite()
}
