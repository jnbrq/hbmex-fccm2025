package hbmex.components.spmv

import chisel3._
import chisel3.util._
import chisel3.experimental.{prefix, noPrefix}
import chisel3.experimental.BundleLiterals._

import chext.amba.axi4
import axi4.Ops._

import chext.elastic
import elastic.ConnectOp._

import hbmex.components.stream
import hbmex.components.spmv.Defs.{wPointer => wPointer}

object Defs {

  /** Width of a pointer. */
  val wPointer = 64

  val wTime = 64

  val wTask = 7 * wPointer
}

class SpmvTask extends Bundle {
  val ptrValues = UInt(Defs.wPointer.W)
  val ptrColumnIndices = UInt(Defs.wPointer.W)
  val ptrRowLengths = UInt(Defs.wPointer.W)
  val ptrInputVector = UInt(Defs.wPointer.W)
  val ptrOutputVector = UInt(Defs.wPointer.W)

  val numValues = UInt(Defs.wPointer.W)
  val numRows = UInt(Defs.wPointer.W)

  require(Defs.wTask == getWidth)
}

/** @param wAddr
  * @param desiredName
  * @param hbmCompat
  *   Only affects the LS port. The GP port is always HBM-compatible.
  */
case class SpmvConfig(
    val wAddr: Int = 32,
    val hbmCompat: Boolean = true,
    val desiredName: String = "Spmv"
) {
  require(wAddr <= Defs.wPointer)

  /** AXI configuration for random-access requests.
    */
  val axiRandomCfg =
    if (hbmCompat)
      axi4.Config(
        wId = 0,
        wAddr = wAddr,
        wData = 256,
        axi3Compat = true,
        hasQos = false,
        hasProt = false,
        hasCache = false,
        hasRegion = false,
        hasLock = false
      )
    else
      axi4.Config(
        wId = 0,
        wAddr = wAddr,
        wData = 256
      )

  /** AXI configuration for the latency-sensitive interface.
    */
  val axiLsMasterCfg = axiRandomCfg

  /** AXI configuration for streaming requests.
    */
  val axiLinearCfg =
    axi4.Config(
      wId = 0,
      wAddr = wAddr,
      wData = 256,
      axi3Compat = true,
      hasQos = false,
      hasProt = false,
      hasCache = false,
      hasRegion = false,
      hasLock = false
    )

  /** AXI configuration for the general-purpose interface.
    */
  val axiGpMasterCfg = axiLinearCfg.copy(wId = 2)

  val responseBufferReadStreamCfg = axi4.full.components.ResponseBufferConfig(
    axiLinearCfg,
    bufLengthR = 32,
    writePassThrough = true
  )

  val readStreamCfg = stream.ReadStreamConfig(
    axiLinearCfg,
    maxBurstLength = 16,
    queueLength = 8
  )

  val writeStreamCfg = stream.WriteStreamConfig(axiLinearCfg, maxBurstLength = 16)

  // HARDCODED
  val downsizeConfig = stream.DownsizeConfig(256, 32)

  val muxCfg = axi4.full.components.MuxConfig(
    readStreamCfg.axiMasterCfg,
    4,
    axi4.BufferConfig.all(16),
    axi4.BufferConfig.all(0),
    elastic.Chooser.rr
  )
}

class Spmv(cfg: SpmvConfig) extends Module {
  import cfg._

  val genTask = new SpmvTask

  val sourceTask = IO(elastic.Source(genTask))

  // How many cycles it took to complete the task
  val sinkDone = IO(elastic.Sink(UInt(Defs.wTime.W)))

  /** Latency-sensitive memory access requests. */
  val m_axi_ls = IO(axi4.full.Master(axiLsMasterCfg))

  /** Latency-insensitive memory access requests. */
  val m_axi_gp = IO(axi4.full.Master(axiGpMasterCfg))

  /** for benchmarking */
  private val rTime = RegInit(0.U(Defs.wTime.W))
  rTime := rTime + 1.U

  private val qTime = Module(new Queue(UInt(Defs.wTime.W), 16))

  private val readStreamValues = Module(new stream.ReadStream(readStreamCfg))
  private val readStreamColumnIndices = Module(new stream.ReadStreamWithLast(readStreamCfg))
  private val readStreamRowLengths = Module(new stream.ReadStream(readStreamCfg))
  private val writeStreamResult = Module(new stream.WriteStream(writeStreamCfg))

  private val responseBufferReadStreamValue = Module(new axi4.full.components.ResponseBuffer(responseBufferReadStreamCfg))
  private val responseBufferReadStreamColumnIndices = Module(new axi4.full.components.ResponseBuffer(responseBufferReadStreamCfg))
  private val responseBufferReadStreamRowLengths = Module(new axi4.full.components.ResponseBuffer(responseBufferReadStreamCfg))

  private val mux = Module(new axi4.full.components.Mux(muxCfg))

  readStreamValues.m_axi :=> responseBufferReadStreamValue.s_axi
  responseBufferReadStreamValue.m_axi :=> mux.s_axi(0)

  readStreamColumnIndices.m_axi :=> responseBufferReadStreamColumnIndices.s_axi
  responseBufferReadStreamColumnIndices.m_axi :=> mux.s_axi(1)

  readStreamRowLengths.m_axi :=> responseBufferReadStreamRowLengths.s_axi
  responseBufferReadStreamRowLengths.m_axi :=> mux.s_axi(2)

  writeStreamResult.m_axi :=> mux.s_axi(3)

  mux.m_axi :=> m_axi_gp

  private val m_axi_random = Wire(axi4.full.Interface(axiRandomCfg))
  m_axi_random :=> m_axi_ls

  private val downsizerValues = Module(new stream.Downsize(downsizeConfig))
  private val downsizerColumnIndices = Module(new stream.DownsizeWithLast(downsizeConfig))
  private val downsizerRowLengths = Module(new stream.Downsize(downsizeConfig))

  readStreamValues.sinkData :=> downsizerValues.source
  readStreamColumnIndices.sinkData :=> downsizerColumnIndices.source
  readStreamRowLengths.sinkData :=> downsizerRowLengths.source

  val rvTask = Wire(Irrevocable(new SpmvTask))

  val rvValues = downsizerValues.sink
  val rvColumnIndices = downsizerColumnIndices.sink
  val rvRowLengths = downsizerRowLengths.sink

  val qPtrInputVector = Module(new Queue(UInt(wPointer.W), 16))

  qTime.io.enq.noenq()
  new elastic.Arrival(sourceTask, rvTask) {
    protected def onArrival: Unit = {
      when(qTime.io.enq.ready) {
        out := in
        qTime.io.enq.enq(rTime)
        accept()

      }.otherwise {
        noAccept()

      }
    }
  }

  new elastic.Fork(rvTask) {
    protected def onFork: Unit = {
      new elastic.Transform(fork(), readStreamValues.sourceTask) {
        protected def onTransform: Unit = {
          out.address := in.ptrValues
          out.length := in.numValues
        }
      }

      new elastic.Transform(fork(), readStreamColumnIndices.sourceTask) {
        protected def onTransform: Unit = {
          out.address := in.ptrColumnIndices
          out.length := in.numValues
        }
      }

      new elastic.Transform(fork(), readStreamRowLengths.sourceTask) {
        protected def onTransform: Unit = {
          out.address := in.ptrRowLengths
          out.length := in.numRows
        }
      }

      new elastic.Transform(fork(), writeStreamResult.sourceTask) {
        protected def onTransform: Unit = {
          out.address := in.ptrOutputVector

          // HARDCODED 3
          out.length := in.numRows << 3
        }
      }

      fork { in.ptrInputVector } :=> qPtrInputVector.io.enq
    }
  }

  val rvPtrInputVector = qPtrInputVector.io.deq
  rvPtrInputVector.nodeq()

  new elastic.Arrival(rvColumnIndices, m_axi_random.ar) {
    protected def onArrival: Unit = {
      out := 0.U.asTypeOf(out)

      when(rvPtrInputVector.valid) {
        // HARDCODED: 3, 2 ** 3 = 8 is the number of vectors processed in parallel
        // HARDCODED: 2, 2 ** 2 = 4 is the number of bytes per value (fp32)
        out.addr := (in.data << (3 + 2)) + rvPtrInputVector.bits
        out.size := 5.U

        accept()

        when(in.last) {
          qPtrInputVector.io.deq.deq()
        }
      }.otherwise {
        noAccept()
      }
    }
  }

  private val batchMultiply = Module(new BatchMultiply)

  downsizerValues.sink :=> elastic.SinkBuffer(batchMultiply.sourceInA)

  new elastic.Transform(m_axi_random.r, elastic.SinkBuffer(batchMultiply.sourceInB)) {
    protected def onTransform: Unit = {
      out := in.data
    }
  }

  private val rowReduce = Module(new RowReduce)

  downsizerRowLengths.sink :=> elastic.SinkBuffer(rowReduce.sourceCount)
  batchMultiply.sinkOut :=> elastic.SinkBuffer(rowReduce.sourceElem)
  rowReduce.sinkResult :=> elastic.SinkBuffer(writeStreamResult.sourceData)

  new elastic.Join(sinkDone) {
    protected def onJoin: Unit = {
      join(writeStreamResult.sinkDone)
      out := rTime - join(qTime.io.deq)
    }
  }

  if (m_axi_random.cfg.write) {
    m_axi_random.aw.noenq()
    m_axi_random.w.noenq()
    m_axi_random.b.nodeq()
  }

  override val desiredName = cfg.desiredName
}

class SpmvAxi(cfg: SpmvConfig, val addResponseBuffer: Boolean = false) extends Module {
  override val desiredName: String = f"${cfg.desiredName}Axi"

  private val spmv = Module(new Spmv(cfg))
  private val memAdapter = Module(new stream.MemAdapter(stream.MemAdapterConfig(Defs.wTime, Defs.wTask, 10)))

  val s_axi = IO(axi4.Slave(memAdapter.s_axil.cfg))
  val m_axi_ls = IO(axi4.Master(cfg.axiLsMasterCfg))
  val m_axi_gp = IO(axi4.Master(cfg.axiGpMasterCfg))

  s_axi.asLite :=> memAdapter.s_axil

  new elastic.Transform(elastic.SourceBuffer(memAdapter.sink, 4), spmv.sourceTask) {
    protected def onTransform: Unit = {
      out := in.asTypeOf(out)
    }
  }

  new elastic.Transform(spmv.sinkDone, elastic.SinkBuffer(memAdapter.source, 4)) {
    protected def onTransform: Unit = {
      out := in.asUInt
    }
  }

  private val responseBufferReadStreamValue = Module(
    new axi4.full.components.ResponseBuffer(
      axi4.full.components.ResponseBufferConfig(
        spmv.m_axi_ls.cfg,
        512,
        2,
        writePassThrough = true
      )
    )
  )
  spmv.m_axi_ls :=> responseBufferReadStreamValue.s_axi
  responseBufferReadStreamValue.m_axi :=> m_axi_ls.asFull

  spmv.m_axi_gp :=> m_axi_gp.asFull
}

object EmitSpmv extends App {
  emitVerilog(new Spmv(SpmvConfig(wAddr = 64, desiredName = "spmv")))
}

object EmitSpmvAxi extends App {
  emitVerilog(new SpmvAxi(SpmvConfig(wAddr = 64, desiredName = "spmv")))
}

object EmitIdParallize extends App {
  val cfg = axi4.full.components.IdParallelizeConfig(
    axiSlaveCfg = axi4.Config(0, 64, 256),
    6
  )
  emitVerilog(new axi4.full.components.IdParallelize(cfg))
}
