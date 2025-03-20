package chext.ip.memory

import chisel3._
import chisel3.util._
import chisel3.experimental.prefix
import chext.elastic.SinkBuffer

class ReadToRawBridge(val rawMemCfg: RawMemConfig, val portCfg: PortConfig = PortConfig())
    extends Module {
  val read = IO(new ReadInterface(rawMemCfg.wAddr, rawMemCfg.wData))
  val raw = IO(Flipped(new RawInterface(rawMemCfg.wAddr, rawMemCfg.wData, true, false)))

  private val rdReq = read.req

  // NOTE: response should be buffered to avoid a combinational connection
  // between ready and valid signals (which would cause a combinational)
  // loop down the line.
  private val rdResp = SinkBuffer(read.resp)

  private val ctr = Module(new chext.util.Counter(portCfg.numOutstandingRead + 1))
  ctr.noInc()
  ctr.noDec()

  private val dataQueue = Module(
    new Queue(
      rdResp.bits.cloneType,
      portCfg.numOutstandingRead,
      flow = true,
      pipe = true
    )
  )

  private val dataQueueEnq = dataQueue.io.enq
  private val dataQueueDeq = dataQueue.io.deq

  dataQueueEnq.noenq()
  dataQueueDeq.nodeq()

  raw.addr := DontCare
  raw.dIn := DontCare
  raw.wstrb := 0.U

  // TODO: you should improve the rdReq ready logic
  //  rdReq.ready := ctr.notFull

  rdReq.nodeq()
  rdResp.noenq()

  when(ctr.notFull && rdReq.valid) {
    raw.addr := rdReq.bits
    rdReq.deq()
  }

  when(rdReq.fire) {
    ctr.inc()
  }

  when(ShiftRegister(rdReq.fire, rawMemCfg.latencyRead)) {
    dataQueueEnq.enq(raw.dOut)
  }

  when(rdResp.ready && dataQueueDeq.valid) {
    rdResp.enq(dataQueueDeq.deq())
    ctr.dec()
  }
}

class WriteToRawBridge(val rawMemCfg: RawMemConfig, val portCfg: PortConfig = PortConfig())
    extends Module {
  val write = IO(new WriteInterface(rawMemCfg.wAddr, rawMemCfg.wData))
  val raw = IO(Flipped(new RawInterface(rawMemCfg.wAddr, rawMemCfg.wData, true, false)))

  private val wrReq = write.req
  private val wrResp = SinkBuffer(write.resp)

  private val ctr = Module(new chext.util.Counter(portCfg.numOutstandingWrite + 1))
  ctr.noInc()
  ctr.noDec()

  private val ctrResp = Module(new chext.util.Counter(portCfg.numOutstandingWrite + 1))
  ctrResp.noInc()
  ctrResp.noDec()

  raw.addr := DontCare
  raw.dIn := DontCare
  raw.wstrb := 0.U

  wrReq.nodeq()
  wrResp.noenq()

  when(ctr.notFull && wrReq.valid) {
    raw.addr := wrReq.bits.addr
    raw.dIn := wrReq.bits.data
    raw.wstrb := wrReq.bits.strb

    wrReq.deq()
  }

  when(wrReq.fire) {
    ctr.inc()
  }

  when(ShiftRegister(wrReq.fire, rawMemCfg.latencyWrite)) {
    ctrResp.inc()
  }

  when(wrResp.ready && ctrResp.notZero) {
    wrResp.enq(0.U)
    ctr.dec()
    ctrResp.dec()
  }
}

class ReadWriteToRawBridge(
    val rawMemCfg: RawMemConfig,
    val portCfg: PortConfig
) extends Module {
  val read = IO(new ReadInterface(rawMemCfg.wAddr, rawMemCfg.wData))
  val write = IO(new WriteInterface(rawMemCfg.wAddr, rawMemCfg.wData))
  val raw = IO(Flipped(new RawInterface(rawMemCfg.wAddr, rawMemCfg.wData, true, true)))

  private val rdReq = read.req
  private val rdResp = SinkBuffer(read.resp)

  private val wrReq = write.req
  private val wrResp = SinkBuffer(write.resp)

  private val ctrRead = Module(new chext.util.Counter(portCfg.numOutstandingRead + 1))
  ctrRead.noInc()
  ctrRead.noDec()

  rdResp.noenq()

  private val ctrWrite = Module(new chext.util.Counter(portCfg.numOutstandingWrite + 1))
  ctrWrite.noInc()
  ctrWrite.noDec()

  private val ctrWriteResp = Module(
    new chext.util.Counter(portCfg.numOutstandingWrite + 1)
  )
  ctrWriteResp.noInc()
  ctrWriteResp.noDec()

  raw.addr := DontCare
  raw.dIn := DontCare
  raw.wstrb := 0.U

  wrResp.noenq()

  prefix("arbiter") {
    val arbiter = Module(portCfg.arbiterFunc())

    arbiter.wrReq := wrReq.valid
    arbiter.rdReq := rdReq.valid

    rdReq.ready := arbiter.chooseRd && ctrRead.notFull
    wrReq.ready := !arbiter.chooseRd && ctrWrite.notFull

    when(rdReq.fire) {
      raw.addr := rdReq.bits
    }

    when(wrReq.fire) {
      raw.addr := wrReq.bits.addr
      raw.dIn := wrReq.bits.data
      raw.wstrb := wrReq.bits.strb
    }
  }

  prefix("read") {
    val dataQueue = Module(
      new Queue(
        rdResp.bits.cloneType,
        portCfg.numOutstandingRead,
        flow = true,
        pipe = true
      )
    )

    val dataQueueEnq = dataQueue.io.enq
    val dataQueueDeq = dataQueue.io.deq

    dataQueueEnq.noenq()
    dataQueueDeq.nodeq()

    when(rdReq.fire) {
      ctrRead.inc()
    }

    when(ShiftRegister(rdReq.fire, rawMemCfg.latencyRead)) {
      dataQueueEnq.enq(raw.dOut)
    }

    when(rdResp.ready && dataQueueDeq.valid) {
      rdResp.enq(dataQueueDeq.deq())
      ctrRead.dec()
    }
  }

  prefix("write") {
    when(wrReq.fire) {
      ctrWrite.inc()
    }

    when(ShiftRegister(wrReq.fire, rawMemCfg.latencyWrite)) {
      ctrWriteResp.inc()
    }
    when(wrResp.ready && ctrWriteResp.notZero) {
      wrResp.enq(0.U)
      ctrWrite.dec()
      ctrWriteResp.dec()
    }
  }
}
