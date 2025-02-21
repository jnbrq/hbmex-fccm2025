package chext.amba.axi4.full.components

import chisel3._
import chisel3.util._
import chisel3.experimental.prefix

import chext.elastic
import elastic.ConnectOp._

import chext.amba.axi4
import axi4.Ops._

import chext.util.BitOps._

private class IdFreeList(val wId: Int) extends Module {
  require(wId <= 30 && wId >= 0)

  val genId = UInt(wId.W)

  val enq = IO(elastic.Source(genId))
  val deq = IO(elastic.Sink(genId))

  private val qIndex = Module(new Queue(genId, 1 << wId))
  private val rIndexSent = RegInit(0.U((wId + 1).W))

  enq :=> qIndex.io.enq

  when(rIndexSent.dropLsbN(wId) === 1.U) {
    // OK, we are out of IDs that were sent
    qIndex.io.deq :=> deq

  }.otherwise {
    qIndex.io.deq.ready := false.B

    deq.valid := true.B
    deq.bits := rIndexSent

    when(deq.ready) {
      rIndexSent := rIndexSent + 1.U
    }
  }
}

private class IdList(val wId: Int) extends Module {
  require(wId <= 30 && wId >= 0)

  val genId = UInt(wId.W)

  val enq = IO(elastic.Source(genId))
  val deq = IO(elastic.Sink(genId))

  private val qIndex = Module(new Queue(genId, 1 << wId))

  enq :=> qIndex.io.enq
  qIndex.io.deq :=> deq
}

/** Creates a memory that supports synchronous writes, elastic reads. If `numOutstandingRead` is zero, uses `Mem` primitive with combinational reads.
  * Otherwise uses the `SRAM` primitive, which has 1-cycle read latency.
  *
  * @param wAddr
  * @param gen
  * @param numOutstandingRead
  */
private class SyncWriteElasticReadMemory[T <: Data](
    val wAddr: Int,
    val gen: T,
    val useSyncMem: Boolean = true
) extends Module {
  require(wAddr >= 0)
  require(wAddr <= 30)

  private val genAddr = UInt(wAddr.W)
  private val rdLatency = 1
  private val numOutstandingRead = 4

  val io = IO(new Bundle {
    val wrEn = Input(Bool())
    val wrAddr = Input(genAddr)
    val wrData = Input(gen)

    val rdReq = Flipped(Decoupled(genAddr))
    val rdResp = Decoupled(gen)
  })

  if (useSyncMem) {
    val sram = SRAM(1 << wAddr, gen, 1, 1, 0)

    sram.writePorts(0).enable := io.wrEn
    sram.writePorts(0).address := io.wrAddr
    sram.writePorts(0).data := io.wrData

    val rdCounter = Module(new chext.util.Counter(numOutstandingRead + 1))
    rdCounter.noInc()
    rdCounter.noDec()

    val rdQueue = Module(new Queue(gen, numOutstandingRead))
    rdQueue.io.enq.noenq()

    io.rdReq.ready := rdCounter.notFull
    rdQueue.io.deq :=> io.rdResp

    sram.readPorts(0).address := DontCare
    sram.readPorts(0).enable := true.B // TODO check this

    when(io.rdReq.fire) {
      sram.readPorts(0).address := io.rdReq.bits
      rdCounter.inc()
    }

    when(ShiftRegister(io.rdReq.fire, rdLatency)) {
      rdQueue.io.enq.enq(sram.readPorts(0).data)
    }

    when(io.rdResp.fire) {
      rdCounter.dec()
    }
  } else {
    val mem = Mem(1 << wAddr, gen)

    when(io.wrEn) {
      mem.write(io.wrAddr, io.wrData)
    }

    io.rdReq.ready := io.rdResp.ready
    io.rdResp.valid := io.rdReq.valid
    io.rdResp.bits := mem.read(io.rdReq.bits)
  }
}

case class IdParallelizeNoReadBurstConfig(
    val axiSlaveCfg: axi4.Config = axi4.Config(wId = 0, wAddr = 12, wData = 64),
    val wIdMaster: Int = 3,
    val readUseSyncMem: Boolean = true,
    val writeUseSyncMem: Boolean = true
) {
  require(axiSlaveCfg.wId == 0)
  require(wIdMaster <= 30)

  val axiMasterCfg = axiSlaveCfg.copy(wId = wIdMaster)
}

class IdParallelizeNoReadBurst(cfg: IdParallelizeNoReadBurstConfig = IdParallelizeNoReadBurstConfig()) extends Module {
  import cfg._

  val s_axi = IO(axi4.full.Slave(axiSlaveCfg))
  val m_axi = IO(axi4.full.Master(axiMasterCfg))

  def implRead(): Unit = prefix("read") {
    val idFreelist = Module(new IdFreeList(wIdMaster))
    val idList = Module(new IdList(wIdMaster))

    val bufferValid = Mem(1 << wIdMaster, Bool())
    val bufferPayload = Module(
      new SyncWriteElasticReadMemory(
        wIdMaster,
        chiselTypeOf(s_axi.r.bits),
        readUseSyncMem
      )
    )

    // === Address Phase ===

    m_axi.ar.bits := s_axi.ar.bits
    m_axi.ar.bits.id := idFreelist.deq.bits

    // idList.enq.ready is always true by construction
    s_axi.ar.ready := m_axi.ar.ready && idFreelist.deq.valid
    m_axi.ar.valid := idFreelist.deq.valid && s_axi.ar.valid

    idFreelist.deq.ready := s_axi.ar.fire

    idList.enq.valid := m_axi.ar.fire
    idList.enq.bits := m_axi.ar.bits.id

    when(s_axi.ar.fire) {
      assert(s_axi.ar.bits.len === 0.U)
    }

    // === Response Phase, master-side ===

    m_axi.r.ready := true.B

    bufferPayload.io.wrEn := m_axi.r.fire
    bufferPayload.io.wrAddr := m_axi.r.bits.id
    bufferPayload.io.wrData := m_axi.r.bits

    when(m_axi.r.fire) {
      bufferValid.write(m_axi.r.bits.id, true.B)
    }

    // === Response Phase, slave-side ===

    // idList.deq.valid is always true if the buffer element is true
    bufferPayload.io.rdReq.bits := idList.deq.bits
    bufferPayload.io.rdReq.valid := bufferValid(idList.deq.bits)

    // idFreeList.enq.valid is always true
    idFreelist.enq.valid := bufferPayload.io.rdReq.fire
    idFreelist.enq.bits := idList.deq.bits

    idList.deq.ready := bufferPayload.io.rdReq.fire

    when(bufferPayload.io.rdReq.fire) {
      bufferValid.write(idList.deq.bits, false.B)

    }

    bufferPayload.io.rdResp :=> s_axi.r

  }

  def implWrite(): Unit = prefix("write") {
    val idFreelist = Module(new IdFreeList(wIdMaster))
    val idList = Module(new IdList(wIdMaster))

    val bufferValid = Mem(1 << wIdMaster, Bool())
    val bufferPayload = Module(
      new SyncWriteElasticReadMemory(
        wIdMaster,
        chiselTypeOf(s_axi.b.bits),
        readUseSyncMem
      )
    )

    // === Address Phase ===

    m_axi.aw.bits := s_axi.aw.bits
    m_axi.aw.bits.id := idFreelist.deq.bits

    // idList.enq.ready is always true by construction
    s_axi.aw.ready := m_axi.aw.ready && idFreelist.deq.valid
    m_axi.aw.valid := idFreelist.deq.valid && s_axi.aw.valid

    idFreelist.deq.ready := s_axi.aw.fire

    idList.enq.valid := m_axi.aw.fire
    idList.enq.bits := m_axi.aw.bits.id

    when(s_axi.aw.fire) {
      assert(s_axi.aw.bits.len === 0.U)
    }

    // === Response Phase, master-side ===

    m_axi.b.ready := true.B

    bufferPayload.io.wrEn := m_axi.b.fire
    bufferPayload.io.wrAddr := m_axi.b.bits.id
    bufferPayload.io.wrData := m_axi.b.bits

    when(m_axi.b.fire) {
      bufferValid.write(m_axi.b.bits.id, true.B)
    }

    // === Response Phase, slave-side ===

    // idList.deq.valid is always true if the buffer element is true
    bufferPayload.io.rdReq.bits := idList.deq.bits
    bufferPayload.io.rdReq.valid := bufferValid(idList.deq.bits)

    // idFreeList.enq.valid is always true
    idFreelist.enq.valid := bufferPayload.io.rdReq.fire
    idFreelist.enq.bits := idList.deq.bits

    idList.deq.ready := bufferPayload.io.rdReq.fire

    when(bufferPayload.io.rdReq.fire) {
      bufferValid.write(idList.deq.bits, false.B)

    }

    bufferPayload.io.rdResp :=> s_axi.b

    s_axi.w :=> m_axi.w
  }

  if (axiSlaveCfg.read)
    implRead()

  if (axiSlaveCfg.write)
    implWrite()
}
