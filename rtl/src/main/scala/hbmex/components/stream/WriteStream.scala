package hbmex.components.stream

import chisel3._
import chisel3.util._
import chisel3.experimental.prefix

import chext.elastic
import elastic.DataLast
import elastic.ConnectOp._

import chext.amba.axi4

import chext.util.BitOps._

class WriteStreamTask extends Bundle {
  val address = UInt(WriteStreamTask.wAddress.W)
  val length = UInt(WriteStreamTask.wLength.W)
}

object WriteStreamTask {
  val wAddress = 64
  val wLength = 64
}

case class WriteStreamConfig(
    val axiMasterCfg: axi4.Config,
    val maxBurstLength: Int = 256,
    val queueLengthB: Int = 16,
    val queueLengthW: Int = 16
) {
  require(!axiMasterCfg.lite)
  require(axiMasterCfg.read)
  require(axiMasterCfg.wAddr <= ReadStreamTask.wAddress)
  require(queueLengthB > 0)

  if (axiMasterCfg.axi3Compat) {
    require(maxBurstLength <= 16, "maxBurstLength <= 16")
  } else {
    require(maxBurstLength <= 256, "maxBurstLength <= 256")
  }

  val wDataSource = axiMasterCfg.wData
}

class WriteStream(val cfg: WriteStreamConfig) extends Module {
  import cfg._

  val genTaskSource = new WriteStreamTask
  val genDataSource = UInt(wDataSource.W)
  val genLength = UInt(ReadStreamTask.wLength.W)

  val m_axi = IO(axi4.full.Master(axiMasterCfg))

  val sourceTask = IO(elastic.Source(genTaskSource))
  val sinkDone = IO(elastic.Sink(UInt(0.W)))

  val sourceData = IO(elastic.Source(genDataSource))

  // Used for counting B packets
  private val qLengthB = Module(new Queue(genLength, queueLengthB))

  // Used for generating the last signal for W packets
  private val qLengthW = Module(new Queue(UInt(axiMasterCfg.wLen.W), queueLengthW))

  private val rvTask0 = Wire(chiselTypeOf(sourceTask))

  prefix("filtering") {
    val arrival0 = new elastic.Arrival(sourceTask, rvTask0) {
      protected def onArrival: Unit = {
        out := in

        when(in.length > 0.U) {
          accept()
        }.otherwise {
          consume()
        }
      }
    }
  }

  prefix("addressPhase") {
    val addressIncrement = maxBurstLength * (axiMasterCfg.wData / 8)

    val rGenerating = RegInit(false.B)
    val rRemaining = RegInit(0.U(WriteStreamTask.wLength.W))
    val rAddress = RegInit(0.U(WriteStreamTask.wAddress.W))

    qLengthW.io.enq.noenq()
    qLengthB.io.enq.noenq()

    val arrival0 = new elastic.Arrival(rvTask0, m_axi.aw) {
      protected def onArrival: Unit = {
        out := 0.U.asTypeOf(out)

        // set up the transfer
        out.burst := 1.U
        out.size := (log2Ceil(axiMasterCfg.wData) - 3).U

        when(qLengthB.io.enq.ready && qLengthW.io.enq.ready) {
          when(rGenerating) {
            when(rRemaining <= maxBurstLength.U) {
              rGenerating := false.B
              rRemaining := 0.U
              rAddress := 0.U

              out.addr := rAddress
              out.len := rRemaining - 1.U

              accept()
            }.otherwise {
              rGenerating := true.B
              rRemaining := rRemaining - maxBurstLength.U
              rAddress := rAddress + addressIncrement.U

              out.addr := rAddress
              out.len := (maxBurstLength - 1).U

              produce()
            }
          }.otherwise {
            when(in.length <= maxBurstLength.U) {
              rGenerating := false.B
              rAddress := 0.U

              out.addr := in.address
              out.len := in.length - 1.U

              accept()
            }.otherwise {
              rGenerating := true.B
              rRemaining := in.length - maxBurstLength.U
              rAddress := in.address + addressIncrement.U

              out.addr := in.address
              out.len := (maxBurstLength - 1).U

              produce()
            }

            // calculate the expected number of Bs
            // do not do this calculation late! deadlock if accepting Bs needed to keep issuing AWs
            // calculate rCountB late, you cannot accept Bs
            qLengthB.io.enq.enq((in.length + (maxBurstLength - 1).U).dropLsbN(log2Ceil(maxBurstLength)) - 1.U)
          }

          qLengthW.io.enq.enq(out.len)
        }.otherwise {
          noAccept()
        }
      }
    }
  }

  prefix("dataPhase") {
    qLengthW.io.deq.nodeq()

    val rReceived = RegInit(0.U(axiMasterCfg.wLen.W))

    val arrival0 = new elastic.Arrival(sourceData, m_axi.w) {
      protected def onArrival: Unit = {
        when(qLengthW.io.deq.valid) {
          out.data := in
          out.strb := (-1).S(out.strb.getWidth.W).asUInt
          out.last := rReceived === qLengthW.io.deq.bits
          out.user := 0.U

          when(out.last) {
            qLengthW.io.deq.deq()
            rReceived := 0.U
          }.otherwise {
            rReceived := rReceived + 1.U
          }

          accept()
        }.otherwise {
          noAccept()
        }
      }
    }
  }

  prefix("responsePhase") {
    qLengthB.io.deq.nodeq()

    val rReceived = RegInit(0.U(ReadStreamTask.wLength.W))

    val arrival0 = new elastic.Arrival(m_axi.b, sinkDone) {
      protected def onArrival: Unit = {
        out := 0.U

        when(qLengthB.io.deq.valid) {
          when(rReceived === qLengthB.io.deq.bits) {
            rReceived := 0.U
            qLengthB.io.deq.deq()

            accept()
          }.otherwise {
            rReceived := rReceived + 1.U

            consume()
          }
        }.otherwise {
          noAccept()
        }
      }
    }
  }

  if (axiMasterCfg.read) {
    m_axi.ar.noenq()
    m_axi.r.nodeq()
  }

  dontTouch(m_axi.aw)
  dontTouch(m_axi.w)
  dontTouch(m_axi.b)
}
