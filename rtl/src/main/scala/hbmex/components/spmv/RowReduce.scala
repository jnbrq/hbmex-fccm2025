package hbmex.components.spmv

import chisel3._
import chisel3.util._

import chext.elastic
import elastic.ConnectOp._
import chisel3.experimental.prefix

class RowReduceSingle extends Module {
  private val batchAddRespBufferSize = 4

  val sourceElem = IO(elastic.Source(new elastic.DataLast(256))) // HARDCODED
  val sinkResult = IO(elastic.Sink(UInt(256.W))) // HARDCODED

  val batchAddReq = IO(elastic.Sink(BatchAdd.genReq))
  val batchAddResp = IO(elastic.Source(BatchAdd.genResp))

  private val requestResponseGuard = Module(new elastic.RequestResponseGuard(BatchAdd.genReq, BatchAdd.genResp, 4))

  private val rvBatchAddInA = Wire(Irrevocable(BatchAdd.genReq._1))
  private val rvBatchAddInB = Wire(Irrevocable(BatchAdd.genReq._2))
  private val rvBatchAddSinkOut = Wire(Irrevocable(BatchAdd.genResp))

  new elastic.Join(requestResponseGuard.sourceReq) {
    protected def onJoin: Unit = {
      out._1 := join(rvBatchAddInA)
      out._2 := join(rvBatchAddInB)
    }
  }

  requestResponseGuard.sinkResp :=> rvBatchAddSinkOut

  requestResponseGuard.sinkReq :=> batchAddReq
  batchAddResp :=> requestResponseGuard.sourceResp

  // HARDCODED
  private val rvResult0 = Wire(Irrevocable(UInt(256.W)))

  // HARDCODED
  private val rvResult1 = Wire(Irrevocable(UInt(256.W)))

  // HARDCODED
  private val rvValue = Wire(Irrevocable(UInt(256.W)))

  private val rvLast0 = Wire(Irrevocable(Bool()))
  private val rvLast1 = Wire(Irrevocable(Bool()))

  private val rvFirst0 = Wire(Irrevocable(Bool()))

  private val rvSelect0 = Wire(Irrevocable(UInt(1.W)))
  private val rvSelect1 = Wire(Irrevocable(UInt(1.W)))

  new elastic.Fork(sourceElem) {
    protected def onFork: Unit = {
      fork { in.data } :=> elastic.SinkBuffer(rvValue)
      fork { in.last.asUInt } :=> rvLast0
      fork { in.last.asUInt } :=> elastic.SinkBuffer(rvLast1)
    }
  }

  private val rIsNextFirst = RegInit(true.B)
  new elastic.Arrival(rvLast0, rvFirst0) {
    protected def onArrival: Unit = {
      out := rIsNextFirst
      accept()

      when(in) {
        // if this is a last packet
        rIsNextFirst := true.B
      }.otherwise {
        rIsNextFirst := false.B
      }
    }
  }

  new elastic.Transform(rvFirst0, rvSelect0) {
    protected def onTransform: Unit = {
      // if this is the first packet, choose zero
      out := (!in).asUInt
    }
  }

  new elastic.Transform(rvLast1, rvSelect1) {
    protected def onTransform: Unit = {
      // if this is the last packet, choose one
      out := in.asUInt
    }
  }

  elastic.Mux(
    sources = Seq(elastic.Constant(0.U(256.W)), rvResult0),
    sink = rvBatchAddInA,
    select = rvSelect0
  )

  elastic.Demux(
    source = rvBatchAddSinkOut,
    sinks = Seq(rvResult0, rvResult1),
    select = rvSelect1
  )

  rvValue :=> rvBatchAddInB
  rvResult1 :=> sinkResult
}

class RowReduce extends Module {
  val sourceElem = IO(elastic.Source(UInt(256.W))) // HARDCODED
  val sourceCount = IO(elastic.Source(UInt(32.W))) // HARDCODED
  val sinkResult = IO(elastic.Sink(UInt(256.W))) // HARDCODED

  // HARDCODED
  // number of single row reducers
  private val log2paramN = 5

  // number of Batch Adds
  private val log2paramK = 2

  private val rowReduceSingleN = Seq.tabulate(1 << log2paramN) { //
    case (index) => Module(new RowReduceSingle)
  }

  for (index <- 0 until (1 << log2paramK))
    prefix(f"batchAddCluster$index") {
      val batchAdd = Module(new BatchAdd)
      val batchAddQueue = Module(new Queue(UInt(log2paramN.W), 16))
      val slice = rowReduceSingleN.slice(index << (log2paramN - log2paramK), (index + 1) << (log2paramN - log2paramK))

      elastic.BasicArbiter(
        slice.map { _.batchAddReq },
        batchAdd.req,
        elastic.Chooser.rr,
        Some(batchAddQueue.io.enq)
      )

      elastic.Demux(
        batchAdd.resp,
        slice.map { _.batchAddResp },
        batchAddQueue.io.deq
      )
    }

  // HARDCODED
  private val rvElem = Wire(Irrevocable(new elastic.DataLast(256)))

  private val rIsGenerating = RegInit(false.B)

  // HARDCODED: 32.W
  private val rRemaining = RegInit(0.U(32.W))

  sourceElem.nodeq()

  // For each rowCount, if the row count is zero, issue
  // an empty element.
  new elastic.Arrival(sourceCount, rvElem) {
    protected def onArrival: Unit = {
      when(rIsGenerating) {
        when(sourceElem.valid) {
          sourceElem.deq()

          when(rRemaining === 1.U) {
            out.data := sourceElem.bits
            out.last := true.B

            rIsGenerating := false.B
            rRemaining := 0.U

            accept()
          }.otherwise {
            out.data := sourceElem.bits
            out.last := false.B

            rRemaining := rRemaining - 1.U

            produce()
          }
        }.otherwise {
          noAccept()
        }
      }.otherwise {
        when(in === 0.U) {
          // this is an empty row, so we should output 0
          out.data := 0.U
          out.last := true.B

          accept()
        }.elsewhen(in === 1.U) {
          when(sourceElem.valid) {
            sourceElem.deq()

            out.data := sourceElem.bits
            out.last := true.B

            accept()
          }.otherwise {
            noAccept()
          }
        }.otherwise {
          when(sourceElem.valid) {
            sourceElem.deq()

            out.data := sourceElem.bits
            out.last := false.B

            rIsGenerating := true.B
            rRemaining := in - 1.U

            produce()
          }.otherwise {
            noAccept()
          }
        }
      }
    }
  }

  elastic.Demux(
    rvElem,
    rowReduceSingleN.map { (x) => elastic.SinkBuffer(x.sourceElem, 32) },
    elastic.Counter(1 << log2paramN),
    (x: elastic.DataLast) => x.last
  )

  elastic.Mux(
    rowReduceSingleN.map { (x) => elastic.SourceBuffer(x.sinkResult) },
    sinkResult,
    elastic.Counter(1 << log2paramN)
  )
}
