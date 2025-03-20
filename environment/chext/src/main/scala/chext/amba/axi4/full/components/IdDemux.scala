package chext.amba.axi4.full.components

import chisel3._
import chisel3.util._
import chisel3.experimental.prefix

import chext.amba.axi4
import chext.elastic

import elastic.ConnectOp._
import chext.util.BitOps._

import axi4.full.{
  AddressChannel,
  WriteDataChannel,
  ReadDataChannel,
  WriteResponseChannel,
  SlaveBuffer,
  MasterBuffer
}

case class IdDemuxConfig(
    val axiSlaveCfg: chext.amba.axi4.Config,
    val wIdSel: Int,
    val capacityPortQueueW: Int = 8,
    val arbiterPolicy: elastic.Chooser.ChooserFn = elastic.Chooser.rr
) {
  require(!axiSlaveCfg.lite)
  require(axiSlaveCfg.read || axiSlaveCfg.write)
  require(wIdSel >= 0)
  require(axiSlaveCfg.wId >= wIdSel)
  require(capacityPortQueueW > 0)

  val numMasters = 1 << wIdSel
  val axiMasterCfg = axiSlaveCfg.copy(wId = axiSlaveCfg.wId - wIdSel)
}

class IdDemux(val cfg: IdDemuxConfig) extends Module {
  import cfg._

  val s_axi = IO(axi4.full.Slave(axiSlaveCfg))
  val m_axi = IO(Vec(numMasters, axi4.full.Master(axiMasterCfg)))

  private val s_axi_ = s_axi
  private val m_axi_ = m_axi

  private val genSelect = UInt(wIdSel.W)

  private def implRead(): Unit = prefix("read") {
    def arLogic: Unit = {
      val demuxInput = Wire(Irrevocable(axi4.full.ReadAddressChannel(axiMasterCfg)))
      val demuxSelect = Wire(Irrevocable(genSelect))

      new elastic.Fork(s_axi_.ar) {
        override protected def onFork = {
          val sel = in.id.lsbN(wIdSel)
          val ar = Wire(axi4.full.ReadAddressChannel(axiMasterCfg))

          ar := in
          ar.id := in.id.dropLsbN(wIdSel)

          fork(ar) :=> demuxInput
          fork(sel) :=> demuxSelect
        }
      }

      elastic.Demux(
        demuxInput,
        m_axi_.map { _.ar },
        demuxSelect
      )
    }

    def rLogic: Unit = {
      val r = Wire(Vec(numMasters, Irrevocable(axi4.full.ReadDataChannel(axiMasterCfg))))

      m_axi_.map { _.r }.zip(r).zipWithIndex.foreach {
        case ((source, sink), index) => {
          new elastic.Transform(source, sink) {
            protected def onTransform: Unit = {
              out := in
              out.id := in.id ## index.U(wIdSel.W)
            }
          }
        }
      }

      // R channel supports burst interleaving, so no isLastFn
      elastic.BasicArbiter(
        r,
        s_axi_.r,
        arbiterPolicy
      )
    }

    arLogic
    rLogic
  }

  private def implWrite(): Unit = prefix("write") {
    val portQueue = Module(
      new Queue(
        genSelect,
        capacityPortQueueW,
        flow = true,
        pipe = true
      )
    )

    def awLogic: Unit = {
      val demuxInput = Wire(Irrevocable(axi4.full.WriteAddressChannel(axiMasterCfg)))
      val demuxSelect = Wire(Irrevocable(genSelect))

      new elastic.Fork(s_axi_.aw) {
        override protected def onFork = {
          val sel = in.id.lsbN(wIdSel)
          val aw = Wire(axi4.full.WriteAddressChannel(axiMasterCfg))

          aw := in
          aw.id := in.id.dropLsbN(wIdSel)

          fork(aw) :=> demuxInput
          fork(sel) :=> demuxSelect
          fork(sel) :=> portQueue.io.enq
        }
      }

      elastic.Demux(demuxInput, m_axi_.map { _.aw }, demuxSelect)
    }

    def wLogic: Unit = {
      // W channel does not support burst interleaving due to the selection logic
      // so isLastFn
      elastic.Demux(
        s_axi_.w,
        m_axi_.map { _.w },
        portQueue.io.deq,
        isLastFn = (x: WriteDataChannel) => x.last
      )
    }

    def bLogic: Unit = {
      val b = Wire(Vec(numMasters, Irrevocable(axi4.full.WriteResponseChannel(axiMasterCfg))))

      m_axi_.map { _.b }.zip(b).zipWithIndex.foreach {
        case ((source, sink), index) => {
          new elastic.Transform(source, sink) {
            protected def onTransform: Unit = {
              out := in
              out.id := in.id ## index.U(wIdSel.W)
            }
          }
        }
      }

      elastic.BasicArbiter(
        b,
        s_axi_.b,
        arbiterPolicy
      )
    }

    awLogic
    wLogic
    bLogic
  }

  if (axiSlaveCfg.read) implRead()
  if (axiSlaveCfg.write) implWrite()
}
