package chext.amba.axi4.full.components

import chext.amba.axi4
import chext.elastic

import chisel3._
import chisel3.util._
import chisel3.experimental._

import axi4.Casts._

import elastic._
import elastic.TransformOp._
import elastic.ConnectOp._

case class IdSerializeConfig(
    val axiSlaveCfg: axi4.Config,
    val capacityIdQueueR: Int = 4,
    val capacityIdQueueW: Int = 4,
    val wIdSelect: Int = 0
) {
  require(!axiSlaveCfg.lite)
  require(axiSlaveCfg.read || axiSlaveCfg.write)

  val axiMasterCfg = axiSlaveCfg.copy(wId = 0)
}

/** Serializes the AXI transactions to a single ID, which is 0.
  *
  * @param axiCfg
  *   AXI configuration of the slave interface.
  */
class IdSerialize(val cfg: IdSerializeConfig) extends Module {
  import cfg._

  val s_axi = IO(axi4.full.Slave(axiSlaveCfg))
  val m_axi = IO(axi4.full.Master(axiMasterCfg))

  private val genId = UInt(axiSlaveCfg.wId.W)

  private def implRead(): Unit = prefix("read") {
    val idQueue = Module(
      new Queue(
        genId,
        cfg.capacityIdQueueR,
        flow = true,
        pipe = true
      )
    )

    idQueue.io.deq.nodeq()

    new Fork(s_axi.ar) {
      protected def onFork: Unit = {
        new Replicate(fork(in), idQueue.io.enq) {
          protected def onReplicate: Unit = {
            len := in.len +& 1.U
            out := in.id
          }
        }

        fork(in) :=> m_axi.ar
      }
    }

    new Transform(m_axi.r, s_axi.r) {
      protected def onTransform: Unit = {
        out := in
        out.id := idQueue.io.deq.bits
      }
    }

    when(s_axi.r.fire) {
      idQueue.io.deq.deq()
    }
  }

  private def implWrite(): Unit = prefix("write") {
    val idQueue = Module(
      new Queue(
        genId,
        cfg.capacityIdQueueR,
        flow = true,
        pipe = true
      )
    )

    new Fork(s_axi.aw) {
      protected def onFork: Unit = {
        fork(in.id) :=> idQueue.io.enq
        fork(in) :=> m_axi.aw
      }
    }

    s_axi.w :=> m_axi.w

    new Join(s_axi.b) {
      protected def onJoin: Unit = {
        val id = join(idQueue.io.deq)

        out := join(m_axi.b)
        out.id := id
      }
    }
  }

  if (axiSlaveCfg.read) implRead()
  if (axiMasterCfg.write) implWrite()
}
