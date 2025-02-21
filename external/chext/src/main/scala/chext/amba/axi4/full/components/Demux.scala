package chext.amba.axi4.full.components

import chext.amba.axi4
import chext.elastic
import chext.bundles

import chisel3._
import chisel3.util._
import chisel3.experimental._

import elastic._
import elastic.ConnectOp._

import axi4.Casts._
import axi4.BufferConfig
import axi4.full.{SlaveBuffer, MasterBuffer, ReadDataChannel, WriteDataChannel}

import bundles._

import elastic.{Chooser, Arrival, Fork}

case class DemuxConfig(
    val axiSlaveCfg: chext.amba.axi4.Config,
    val numMasters: Int = 4,
    val decodeFn: (UInt) => (UInt),
    val numIdsTrackedRead: Int = 4,
    val numIdsTrackedWrite: Int = 4,
    val numOutstandingRead: Int = 16,
    val numOutstandingWrite: Int = 16,
    val capacityPortQueueW: Int = 8,
    val slaveBuffers: BufferConfig = BufferConfig.all(2),
    val masterBuffers: BufferConfig = BufferConfig.all(0),
    val arbiterPolicy: Chooser.ChooserFn = Chooser.rr
) {
  require(!axiSlaveCfg.lite)
  require(axiSlaveCfg.read || axiSlaveCfg.write)
  require(numMasters > 0)

  require(numIdsTrackedRead > 0)
  require(numIdsTrackedWrite > 0)
  require(numOutstandingRead > 0)
  require(numOutstandingWrite > 0)
  require(capacityPortQueueW > 0)

  val wIdTrackedRead: Int = log2Ceil(numIdsTrackedRead + 1)
  val wIdTrackedWrite: Int = log2Ceil(numIdsTrackedWrite + 1)
  val wOutstandingRead: Int = log2Ceil(numOutstandingRead + 1)
  val wOutstandingWrite: Int = log2Ceil(numOutstandingWrite + 1)

  val wPort = log2Ceil(numMasters)

  val axiMasterCfg = axiSlaveCfg
}

class Demux(val cfg: DemuxConfig) extends Module {
  import cfg._

  val s_axi = IO(axi4.full.Slave(axiSlaveCfg))
  val m_axi = IO(Vec(numMasters, axi4.full.Master(axiMasterCfg)))

  private val s_axi_ = SlaveBuffer(s_axi, slaveBuffers)
  private val m_axi_ = m_axi.map { (x) =>
    MasterBuffer(x, masterBuffers)
  }

  private val genPort = UInt(wPort.W)

  private def implRead(): Unit = prefix("read") {
    val transactionTracker = Module(
      new helpers.TransactionTracker(
        wIdTrackedRead,
        wPort,
        wOutstandingRead
      )
    )

    transactionTracker.noQuery()
    transactionTracker.noComplete()
    transactionTracker.noInitiate()

    def arLogic: Unit = {
      val genArPort = new Bundle2(s_axi_.ar.bits.cloneType, genPort)
      val arPort = Wire(Irrevocable(genArPort))

      new Arrival(s_axi_.ar, arPort) {
        override protected def onArrival: Unit = {
          val id = in.id
          val addr = in.addr
          val port = decodeFn(addr)

          out._1 := in
          out._2 := port

          when(transactionTracker.canInitiate(id, port)) {
            transactionTracker.initiate(id, port)
            accept()
          }.otherwise {
            noAccept()
          }
        }
      }

      val demuxInput = Wire(Irrevocable(s_axi_.ar.bits.cloneType))
      val demuxSelect = Wire(Irrevocable(genPort))

      new Fork(arPort) {
        override protected def onFork = {
          fork(in._1) :=> demuxInput
          fork(in._2) :=> demuxSelect
        }
      }

      chext.elastic.Demux(
        demuxInput,
        m_axi_.map { _.ar },
        demuxSelect
      )
    }

    def rLogic: Unit = {
      // R channel supports burst interleaving, so no isLastFn
      chext.elastic.BasicArbiter(
        m_axi_.map { _.r },
        s_axi_.r,
        arbiterPolicy
      )

      when(s_axi_.r.fire && s_axi_.r.bits.last) {
        transactionTracker.complete(s_axi_.r.bits.id)
      }
    }

    arLogic
    rLogic
  }

  private def implWrite(): Unit = prefix("write") {
    val transactionTracker = Module(
      new helpers.TransactionTracker(
        wIdTrackedWrite,
        wPort,
        wOutstandingWrite
      )
    )

    transactionTracker.noQuery()
    transactionTracker.noComplete()
    transactionTracker.noInitiate()

    val portQueue = Module(
      new Queue(
        genPort,
        capacityPortQueueW,
        flow = true,
        pipe = true
      )
    )

    def awLogic: Unit = {
      val genAwPort = new Bundle2(s_axi_.aw.bits.cloneType, genPort)
      val awPort = Wire(Irrevocable(genAwPort))

      new Arrival(s_axi_.aw, awPort) {
        protected def onArrival: Unit = {
          val id = in.id
          val addr = in.addr
          val port = decodeFn(addr)

          out._1 := in
          out._2 := port

          when(transactionTracker.canInitiate(id, port)) {
            transactionTracker.initiate(id, port)
            accept()
          }.otherwise {
            noAccept()
          }
        }
      }

      val demuxInput = Wire(Irrevocable(s_axi_.aw.bits.cloneType))
      val demuxSelect = Wire(Irrevocable(genPort))

      new Fork(awPort) {
        override protected def onFork = {
          fork(in._1) :=> demuxInput
          fork(in._2) :=> demuxSelect
          fork(in._2) :=> portQueue.io.enq
        }
      }

      chext.elastic.Demux(demuxInput, m_axi_.map { _.aw }, demuxSelect)
    }

    def wLogic: Unit = {
      // W channel does not support burst interleaving due to the selection logic
      // so isLastFn
      chext.elastic.Demux(
        s_axi_.w,
        m_axi_.map { _.w },
        portQueue.io.deq,
        isLastFn = (x: WriteDataChannel) => x.last
      )
    }

    def bLogic: Unit = {
      chext.elastic.BasicArbiter(
        m_axi_.map { _.b },
        s_axi_.b,
        arbiterPolicy
      )

      when(s_axi_.b.fire) {
        transactionTracker.complete(s_axi_.b.bits.id)
      }
    }

    awLogic
    wLogic
    bLogic
  }

  if (axiSlaveCfg.read) implRead()
  if (axiSlaveCfg.write) implWrite()
}

object DemuxEmitter extends App {
  def demuxModule = new Demux(
    DemuxConfig(
      chext.amba.axi4.Config(
        wId = 4,
        wAddr = 32,
        wData = 256,
        read = true,
        write = true,
        lite = false
      ),
      8,
      (_ >> 8)
    )
  )

  emitVerilog(demuxModule, Array("--target-dir", "output/"))
}
