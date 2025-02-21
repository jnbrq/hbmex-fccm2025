package chext.elastic

import chisel3._
import chisel3.util._

import chext.elastic
import elastic.ConnectOp._

/** Stops issuing requests if there is no sufficient buffer space. Useful for avoiding deadlocks in case of a shared resource.
  *
  * @param genReq
  * @param genResp
  * @param numEntries
  */
class RequestResponseGuard[Req <: Data, Resp <: Data](genReq: Req, genResp: Resp, numEntries: Int) extends Module {
  val sourceReq = IO(elastic.Source(genReq))
  val sinkResp = IO(elastic.Sink(genResp))

  val sinkReq = IO(elastic.Sink(genReq))
  val sourceResp = IO(elastic.Source(genResp))

  private val ctr = Module(new chext.util.Counter(numEntries + 1))
  ctr.noInc()
  ctr.noDec()

  private val respQueue = Module(new Queue(genResp, numEntries))

  new elastic.Arrival(sourceReq, sinkReq) {
    protected def onArrival: Unit = {
      out := in

      when(ctr.full) {
        noAccept()
      }.otherwise {
        ctr.inc()
        accept()
      }
    }
  }

  sourceResp :=> respQueue.io.enq

  new elastic.Arrival(respQueue.io.deq, sinkResp) {
    protected def onArrival: Unit = {
      out := in

      ctr.dec()
      accept()
    }
  }
}
