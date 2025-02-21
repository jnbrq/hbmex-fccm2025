package chext.amba.axi4.full.components

import chisel3._
import chisel3.util._
import chisel3.experimental.prefix

import chext.util.BitOps._
import chext.bundles.BundleN

import chext.amba.axi4
import chext.elastic

import elastic.{Source, Sink, SinkBuffer}
import elastic.ConnectOp._

import chext.ip.memory

case class IdParallelizeConfig(
    val axiSlaveCfg: axi4.Config = axi4.Config(wId = 0, wAddr = 12, wData = 64),
    val wIdMaster: Int = 3,
    val wBufferIndex: Int = 10,
    val readUseSyncMem: Boolean = true,
    val writeUseSyncMem: Boolean = true
) {
  require(axiSlaveCfg.wId == 0)
  val axiMasterCfg = axiSlaveCfg.copy(wId = wIdMaster)

  // pedantic, to avoid overflows in the calculations
  assert(wIdMaster <= 30)
  assert(wBufferIndex <= 30)
}

/** Creates a memory that supports synchronous writes, elastic reads. If `numOutstandingRead` is
  * zero, uses `Mem` primitive with combinational reads. Otherwise uses the `SRAM` primitive, which
  * has 1-cycle read latency.
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

class IdParallelize(cfg: IdParallelizeConfig = IdParallelizeConfig()) extends Module {
  import cfg._

  val s_axi = IO(axi4.full.Slave(axiSlaveCfg))
  val m_axi = IO(axi4.full.Master(axiMasterCfg))

  def implRead(): Unit = prefix("read") {
    val s_ar = s_axi.ar
    val m_ar = SinkBuffer(m_axi.ar)

    val s_r = SinkBuffer(s_axi.r)
    val m_r = m_axi.r

    val genIndex = UInt(wBufferIndex.W)
    val bufferCapacity = (1 << wBufferIndex).U((wBufferIndex + 1).W)

    val xIndexFill = Mem(1 << wIdMaster, genIndex)

    val bufferValid = Mem(1 << wBufferIndex, Bool())
    val bufferPayload = Module(
      new SyncWriteElasticReadMemory(
        wBufferIndex,
        chiselTypeOf(s_axi.r.bits),
        readUseSyncMem
      )
    )

    // 1 extra bit set when no more IDs are available
    val nextIdFill = RegInit(0.U((wIdMaster + 1).W))

    val nextIndexFill = RegInit(0.U(wBufferIndex.W))
    val nextIndexDrain = RegInit(0.U(wBufferIndex.W))

    val bufferAvailable = RegInit(bufferCapacity)

    val xCount = Module(new chext.util.Counter((1 << wIdMaster) + 1))
    xCount.noInc()
    xCount.noDec()

    s_ar.ready :=
      m_ar.ready &&
        !nextIdFill.dropLsbN(wIdMaster) &&
        (bufferAvailable >= (s_ar.bits.len + 1.U))

    m_ar.bits := s_ar.bits
    m_ar.bits.id := nextIdFill
    m_ar.valid := s_ar.fire // m_ar.valid := m_ar.ready (comb loop) && s_ar.valid && ...

    m_r.ready := true.B // we always have space in the buffer if the transaction goes through

    bufferPayload.io.rdResp :=> s_r

    when(s_ar.fire /* eqv to m_ar.fire */ ) {
      xIndexFill.write(nextIdFill, nextIndexFill)

      nextIndexFill := nextIndexFill + s_ar.bits.len + 1.U
      nextIdFill := nextIdFill + 1.U
      bufferAvailable := bufferAvailable - (s_ar.bits.len + 1.U)

      xCount.inc()
    }

    bufferPayload.io.wrEn := m_r.fire
    bufferPayload.io.wrAddr := xIndexFill(m_r.bits.id)
    bufferPayload.io.wrData := m_r.bits

    when(m_r.fire) {
      xIndexFill.write(m_r.bits.id, xIndexFill.read(m_r.bits.id) + 1.U)
      bufferValid.write(xIndexFill(m_r.bits.id), true.B)
    }

    bufferPayload.io.rdReq.bits := nextIndexDrain
    bufferPayload.io.rdReq.valid := bufferValid.read(nextIndexDrain)

    when(bufferPayload.io.rdReq.fire) {
      bufferValid.write(nextIndexDrain, false.B)
      nextIndexDrain := nextIndexDrain + 1.U
    }

    when(s_r.fire) {
      when(s_r.bits.last) {
        xCount.dec()
      }
    }

    when(xCount.zero && !s_ar.fire) {
      nextIdFill := 0.U
      nextIndexFill := 0.U
      nextIndexDrain := 0.U

      bufferAvailable := bufferCapacity
    }
  }

  def implWrite(): Unit = prefix("write") {
    val s_aw = s_axi.aw
    val m_aw = SinkBuffer(m_axi.aw)

    val s_b = SinkBuffer(s_axi.b)
    val m_b = m_axi.b

    val bufferValid = Mem(1 << wIdMaster, Bool())
    val bufferPayload = Module(
      new SyncWriteElasticReadMemory(
        wIdMaster,
        chiselTypeOf(s_axi.b.bits),
        writeUseSyncMem
      )
    )

    val nextIdFill = Reg(UInt((wIdMaster + 1).W))
    val nextIdDrain = Reg(UInt(wIdMaster.W))

    val xCount = Module(new chext.util.Counter((1 << wIdMaster) + 1))
    xCount.noInc()
    xCount.noDec()

    s_aw.ready :=
      m_aw.ready &&
        !nextIdFill.dropLsbN(wIdMaster)

    m_aw.bits := s_aw.bits
    m_aw.bits.id := nextIdFill
    m_aw.valid := s_aw.fire // m_ar.valid := m_ar.ready (comb loop) && s_ar.valid && ...

    m_b.ready := true.B // we always have space in the buffer if the transaction goes through

    bufferPayload.io.rdResp :=> s_b

    when(s_aw.fire) {
      nextIdFill := nextIdFill + 1.U
      xCount.inc()
    }

    bufferPayload.io.wrEn := m_b.fire
    bufferPayload.io.wrAddr := m_b.bits.id
    bufferPayload.io.wrData := m_b.bits

    when(m_b.fire) {
      bufferValid.write(m_b.bits.id, true.B)
    }

    bufferPayload.io.rdReq.bits := nextIdDrain
    bufferPayload.io.rdReq.valid := bufferValid.read(nextIdDrain)

    when(bufferPayload.io.rdReq.fire) {
      bufferValid.write(nextIdDrain, false.B)
      nextIdDrain := nextIdDrain + 1.U
    }

    when(s_b.fire) {
      xCount.dec()
    }

    when(xCount.zero && !s_aw.fire) {
      nextIdFill := 0.U
      nextIdDrain := 0.U
    }

    s_axi.w :=> m_axi.w
  }

  if (axiSlaveCfg.read)
    implRead()

  if (axiSlaveCfg.write)
    implWrite()
}
