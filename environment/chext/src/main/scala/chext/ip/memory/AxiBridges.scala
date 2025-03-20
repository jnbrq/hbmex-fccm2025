package chext.ip.memory

import chisel3._
import chisel3.util._

import chext.elastic
import chext.amba.axi4

import axi4.full.components._

import elastic.{Fork, Join, Replicate, Transform, Arrival}
import elastic.ConnectOp._
import chisel3.experimental.prefix

private class IdLastBundle(wId: Int) extends Bundle {
  val id = UInt(wId.W)
  val last = Bool()
}

class Axi4FullToReadWriteBridge(val cfg: axi4.Config) extends Module {
  private val idBufferLength: Int = 4
  private val addrShift = log2Ceil(cfg.wData >> 3)
  private val wWordAddr = cfg.wAddr - addrShift
  private val wData = cfg.wData

  assert(cfg.read && cfg.write && !cfg.lite)

  val s_axi = IO(axi4.full.Slave(cfg))
  val read = IO(Flipped(new ReadInterface(wWordAddr, wData)))
  val write = IO(Flipped(new WriteInterface(wWordAddr, wData)))

  private def implRead() = prefix("read") {
    val addressGenerator = Module(new AddressGenerator(cfg.wAddr))
    val idLast = Wire(Irrevocable(new IdLastBundle(cfg.wId)))

    val fork1 = new Fork(s_axi.ar) {
      protected def onFork: Unit = {
        // TODO: determine the size of the replicate in a better way
        // 4 is good enough for full throughput

        val replicate1 = new Replicate(fork(), elastic.SinkBuffer(idLast, idBufferLength)) {
          protected def onReplicate: Unit = {
            len := in.len +& 1.U
            out.id := in.id
            out.last := last
          }
        }

        val transform1 = new Transform(fork(), addressGenerator.source) {
          protected def onTransform: Unit = {
            out.addr := in.addr
            out.len := in.len
            out.size := in.size
            out.burst := in.burst
          }
        }
      }
    }

    val transform2 = new Transform(addressGenerator.sink, read.req) {
      protected def onTransform: Unit = {
        out := in.addr >> addrShift
      }
    }

    val join1 = new Join(s_axi.r) {
      protected def onJoin: Unit = {
        val resp = join(read.resp)
        val id = join(idLast)

        out.data := resp
        out.id := id.id
        out.resp := axi4.ResponseFlag.OKAY
        out.user := 0.U // TODO: propagate the user data, maybe?
        out.last := id.last
      }
    }
  }

  private def implWrite() = prefix("write") {
    val addressStrobeGenerator = Module(new AddressStrobeGenerator(cfg.wAddr, wData))
    val idLast = Wire(Irrevocable(new IdLastBundle(cfg.wId)))

    val fork1 = new Fork(s_axi.aw) {
      protected def onFork: Unit = {
        // TODO: determine the size of the replicate in a better way
        val replicate1 = new Replicate(fork(), elastic.SinkBuffer(idLast, idBufferLength)) {
          protected def onReplicate: Unit = {
            len := in.len +& 1.U
            out.id := in.id
            out.last := last
          }
        }

        val transform1 = new Transform(fork(), addressStrobeGenerator.source) {
          protected def onTransform: Unit = {
            out.addr := in.addr
            out.len := in.len
            out.size := in.size
            out.burst := in.burst
          }
        }
      }
    }

    val join1 = new Join(write.req) {
      protected def onJoin: Unit = {
        val addrStrobe = join(addressStrobeGenerator.sink)
        val w = join(s_axi.w)

        out.addr := addrStrobe.addr >> addrShift
        out.data := w.data
        out.strb := addrStrobe.strb & w.strb
      }
    }

    val idLastJoined = Wire(Irrevocable(new IdLastBundle(cfg.wId)))

    val join2 = new Join(idLastJoined) {
      protected def onJoin: Unit = {
        out := join(idLast)
        join(write.resp)
      }
    }

    val arrival1 = new Arrival(idLastJoined, s_axi.b) {
      protected def onArrival: Unit = {
        consume()

        when(in.last) {
          out.id := in.id
          out.resp := axi4.ResponseFlag.OKAY
          out.user := 0.U // TODO: propagate the user data, maybe?
          produce()
        }
      }
    }
  }

  implRead()
  implWrite()
}

class Axi4LiteToReadWriteBridge(cfg: axi4.Config) extends Module {
  private val addrShift = log2Ceil(cfg.wData >> 3)
  private val wWordAddr = cfg.wAddr - addrShift
  private val wData = cfg.wData

  assert(cfg.read && cfg.write && cfg.lite)

  val s_axil = IO(axi4.lite.Slave(cfg))
  val read = IO(Flipped(new ReadInterface(wWordAddr, wData)))
  val write = IO(Flipped(new WriteInterface(wWordAddr, wData)))

  private def implRead() = prefix("read") {
    val transform1 = new Transform(s_axil.ar, read.req) {
      protected def onTransform: Unit = {
        out := in.addr >> addrShift
      }
    }

    val transform2 = new Transform(read.resp, s_axil.r) {
      protected def onTransform: Unit = {
        out.data := in
        out.resp := axi4.ResponseFlag.OKAY
      }
    }
  }
  implRead()

  private def implWrite() = prefix("write") {
    val join1 = new Join(write.req) {
      protected def onJoin: Unit = {
        val aw = join(s_axil.aw)
        val w = join(s_axil.w)

        out.addr := aw.addr >> addrShift
        out.data := w.data
        out.strb := w.strb
      }
    }

    val transform1 = new Transform(write.resp, s_axil.b) {
      protected def onTransform: Unit = {
        out.resp := axi4.ResponseFlag.OKAY
      }
    }
  }
  implWrite()
}
