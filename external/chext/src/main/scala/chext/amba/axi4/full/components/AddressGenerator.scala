package chext.amba.axi4.full.components

import chext.amba.axi4
import chext.elastic

import chisel3._
import chisel3.util._
import chisel3.experimental._
import chisel3.experimental.BundleLiterals._

import elastic.ConnectOp._

import axi4.Casts._

import axi4.BurstType
import axi4.full.{AddressChannel, ReadAddressChannel, WriteAddressChannel}
import elastic.{Source, Sink, SourceBuffer, SinkBuffer}

class AddrLenSizeBurstBundle(val wAddr: Int) extends Bundle {
  val addr = UInt(wAddr.W)
  val len = UInt(8.W)
  val size = UInt(3.W)
  val burst = UInt(2.W)
}

class AddrSizeLastBundle(val wAddr: Int) extends Bundle {
  val addr = UInt(wAddr.W)
  val size = UInt(3.W)
  val last = Bool()
}

class AddrSizeStrobeLastBundle(val wAddr: Int, val wData: Int) extends Bundle {
  assert(isPow2(wData) && wData >= 32)

  val wStrobe = wData / 8

  val addr = UInt(wAddr.W)
  val size = UInt(3.W)
  val strb = UInt(wStrobe.W)
  val lowerByteIndex = UInt(log2Ceil(wStrobe).W)
  val upperByteIndex = UInt(log2Ceil(wStrobe).W)

  val last = Bool()
}

/** @brief
  *   Decodes an address packet by calculating the addresses corresponding to each beat of the
  *   transaction.
  */
class AddressGenerator(val wAddr: Int) extends Module {
  val genSource = new AddrLenSizeBurstBundle(wAddr)
  val genSink = new AddrSizeLastBundle(wAddr)

  val source = IO(Source(Irrevocable(genSource)))
  val sink = IO(Sink(Irrevocable(genSink)))

  private val source_ = SourceBuffer(source)
  private val sink_ = SinkBuffer(sink)

  private val current = source_.bits

  /** Current address to emit (INCR bursts). */
  private val addr = Reg(UInt(wAddr.W))

  /** Beat counter. */
  private val ctr = Reg(UInt(8.W))

  /** Flag for generating right now. */
  private val generating = RegInit(false.B)

  source_.nodeq()
  sink_.noenq()

  when(source_.valid && sink_.ready) {
    when(generating) {
      val last = ctr === 0.U

      when(last) {
        generating := false.B
        source_.deq()
      }.otherwise {
        ctr := ctr - 1.U

        when(current.burst === BurstType.INCR) {
          addr := addr + 1.U
        }.elsewhen(current.burst === BurstType.WRAP) {
          val mask1 = current.len + 0.U(wAddr.W)
          val mask2 = ~mask1
          addr := (addr & mask2) | (((addr + 1.U) & mask1))
        }
      }

      when(current.burst === BurstType.FIXED) {
        sink_.enq {
          val result = Wire(genSink)
          result.addr := current.addr
          result.size := current.size
          result.last := last

          result
        }
      }.otherwise {
        sink_.enq {
          val result = Wire(genSink)
          result.addr := addr << current.size
          result.size := current.size
          result.last := last

          result
        }
      }
    }.otherwise {
      val last = current.len === 0.U

      when(last) {
        source_.deq()
      }.otherwise {
        generating := true.B
        addr := ((current.addr >> current.size) + 1.U)
        ctr := current.len - 1.U
      }

      sink_.enq {
        val result = Wire(genSink)
        result.addr := current.addr
        result.size := current.size
        result.last := last

        result
      }
    }
  }
}

class StrobeGenerator(val wAddr: Int, val wData: Int) extends Module {
  val genInput = new AddrSizeLastBundle(wAddr)
  val genOutput = new AddrSizeStrobeLastBundle(wAddr, wData)

  val source = IO(Source(Irrevocable(genInput)))
  val sink = IO(Sink(Irrevocable(genOutput)))

  private val wStrobe = genOutput.wStrobe
  private val log2strobe = log2Ceil(wStrobe)

  new elastic.Transform(source, sink) {
    protected def onTransform: Unit = {
      val addr = in.addr(log2strobe - 1, 0)

      // we should preserve the lower bits for unaligned transactions
      val lowerByteIndex = addr

      // we should not preserve the lower bits
      val upperByteIndex = ((1.U + (addr >> in.size)) << in.size) - 1.U

      /* pass through */
      out.addr := in.addr
      out.size := in.size
      out.last := in.last

      out.lowerByteIndex := lowerByteIndex
      out.upperByteIndex := upperByteIndex

      /* TODO: is there a better way to optimize this? */
      out.strb := VecInit
        .tabulate(wStrobe) { (idx) =>
          (idx.U <= upperByteIndex) && (idx.U >= lowerByteIndex)
        }
        .asUInt
    }
  }
}

class AddressStrobeGenerator(val wAddr: Int, val wData: Int) extends Module {
  private val addressGenerator = Module(new AddressGenerator(wAddr))
  private val strobeGenerator = Module(new StrobeGenerator(wAddr, wData))

  val genInput = addressGenerator.genSource
  val genOutput = strobeGenerator.genOutput

  val source = IO(Source(Irrevocable(genInput)))
  val sink = IO(Sink(Irrevocable(genOutput)))

  source :=> addressGenerator.source
  addressGenerator.sink :=> strobeGenerator.source
  strobeGenerator.sink :=> sink
}
