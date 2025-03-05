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
  *   Only affects the random access port. The regular access port is always HBM-compatible.
  */
case class SpmvConfig(
    val wAddr: Int = 32,
    val hbmCompat: Boolean = true,
    val useResponseBufferRandom: Boolean = true,
    val desiredName: String = "Spmv"
) {
  require(wAddr <= Defs.wPointer)

  /** AXI configuration for random-access requests.
    */
  val axiRandomMasterCfg =
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

  /** AXI configuration for streaming requests.
    */
  val axiRegularMasterCfg =
    axi4.Config(
      wId = 2,
      wAddr = wAddr,
      wData = 256,
      axi3Compat = true,
      hasQos = false,
      hasProt = false,
      hasCache = false,
      hasRegion = false,
      hasLock = false
    )

  val responseBufferRegularCfg = axi4.full.components.ResponseBufferConfig(
    axiRegularMasterCfg.copy(wId = 0),

    // HARDCODED
    bufLengthR = 32,
    writePassThrough = true
  )

  val responseBufferRandomCfg = axi4.full.components.ResponseBufferConfig(
    axiRandomMasterCfg,

    // HARDCODED: random access response buffer length
    bufLengthR = 512,
    writePassThrough = true
  )

  val readStreamCfg = stream.ReadStreamConfig(
    axiRegularMasterCfg.copy(wId = 0),

    // HARDCODED: burst length
    maxBurstLength = 16,
    queueLength = 8
  )

  val writeStreamCfg = stream.WriteStreamConfig(
    axiRegularMasterCfg.copy(wId = 0),

    // HARDCODED: burst length
    maxBurstLength = 16
  )

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

  /** Random memory access requests. */
  val m_axi_random = IO(axi4.full.Master(axiRandomMasterCfg))

  /** Regular memory access requests. */
  val m_axi_regular = IO(axi4.full.Master(axiRegularMasterCfg))

  /** for benchmarking */
  private val rTime = RegInit(0.U(Defs.wTime.W))
  rTime := rTime + 1.U

  private val qTime = Module(new Queue(UInt(Defs.wTime.W), 16))

  private val readStreamValues = Module(new stream.ReadStream(readStreamCfg))
  private val readStreamColumnIndices = Module(new stream.ReadStreamWithLast(readStreamCfg))
  private val readStreamRowLengths = Module(new stream.ReadStream(readStreamCfg))
  private val writeStreamResult = Module(new stream.WriteStream(writeStreamCfg))

  // TODO: Maybe we should use a response buffer embedded in the stream later?
  // These response buffers avoid deadlocks due to sharing of the master interface
  private val responseBufferValue = Module(new axi4.full.components.ResponseBuffer(responseBufferRegularCfg))
  private val responseBufferColumnIndices = Module(new axi4.full.components.ResponseBuffer(responseBufferRegularCfg))
  private val responseBufferRowLengths = Module(new axi4.full.components.ResponseBuffer(responseBufferRegularCfg))

  private val mux = Module(new axi4.full.components.Mux(muxCfg))

  readStreamValues.m_axi :=> responseBufferValue.s_axi
  responseBufferValue.m_axi :=> mux.s_axi(0)

  readStreamColumnIndices.m_axi :=> responseBufferColumnIndices.s_axi
  responseBufferColumnIndices.m_axi :=> mux.s_axi(1)

  readStreamRowLengths.m_axi :=> responseBufferRowLengths.s_axi
  responseBufferRowLengths.m_axi :=> mux.s_axi(2)

  writeStreamResult.m_axi :=> mux.s_axi(3)

  mux.m_axi :=> m_axi_regular

  private val m_axi_random_ = Wire(axi4.full.Interface(axiRandomMasterCfg))

  if (useResponseBufferRandom) {
    val responseBufferRandom = Module(new axi4.full.components.ResponseBuffer(responseBufferRandomCfg))
    m_axi_random_ :=> responseBufferRandom.s_axi
    responseBufferRandom.m_axi :=> m_axi_random
  } else {
    m_axi_random_ :=> m_axi_random
  }

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

  new elastic.Arrival(rvColumnIndices, m_axi_random_.ar) {
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

  new elastic.Transform(m_axi_random_.r, elastic.SinkBuffer(batchMultiply.sourceInB)) {
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

  if (m_axi_random_.cfg.write) {
    m_axi_random_.aw.noenq()
    m_axi_random_.w.noenq()
    m_axi_random_.b.nodeq()
  }

  override val desiredName = cfg.desiredName
}

object EmitSpmv extends App {
  emitVerilog(new Spmv(SpmvConfig(wAddr = 64, desiredName = "spmv")))
}
