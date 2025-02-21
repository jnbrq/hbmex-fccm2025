package chext.ip.memory.chisel

import chisel3._
import chisel3.util._

import chext.ip.memory

private object unpack {
  def apply(in: UInt, elemWidth: Int): Vec[UInt] = {
    assert(in.getWidth >= elemWidth && in.getWidth % elemWidth == 0)
    val length = in.getWidth / elemWidth
    val unpacked = Wire(Vec(length, UInt(elemWidth.W)))
    unpacked.zipWithIndex.foreach {
      case (elem, idx) => {
        elem := in(elemWidth * (idx + 1) - 1, elemWidth * idx)
      }
    }
    unpacked
  }
}

class SinglePortRawRAM(
    val cfg: memory.RawMemConfig
) extends Module
    with memory.RawMem {
  override val desiredName = "ChiselSimpleDualPortMem"

  assert(cfg.latencyRead >= 1)
  assert(cfg.latencyWrite >= 1)

  val raw = IO(
    new memory.RawInterface(cfg.wAddr, cfg.wData, true, true)
  )

  private val numBytes =
    (cfg.wData >> 3) // NOTE: same as the write strobe width

  private val mem =
    SyncReadMem(1 << cfg.wAddr, Vec(numBytes, UInt(8.W)))
  private class WrReq(val wAddr: Int, val wData: Int) extends Bundle {
    val wStrobe = (wData >> 3)

    val addr = UInt(wAddr.W)
    val dIn = Bits(wData.W)
    val wstrb = UInt(wStrobe.W)
  }

  private def impl(raw: memory.RawInterface) = {

    val wrReq_ = Wire(new WrReq(wAddr = cfg.wAddr, wData = cfg.wData))
    wrReq_.addr := raw.addr
    wrReq_.dIn := raw.dIn
    wrReq_.wstrb := raw.wstrb

    val wrReqDelayed_ =
      if (cfg.latencyRead > 1) ShiftRegister(wrReq_, cfg.latencyWrite - 1)
      else wrReq_

    mem.write(
      wrReqDelayed_.addr,
      unpack(wrReqDelayed_.dIn, 8),
      wrReqDelayed_.wstrb.asBools
    )
    raw.dOut := 0.U

    val dOut_ = mem.read(raw.addr, true.B).asUInt

    raw.dOut := {
      if (cfg.latencyRead > 1) ShiftRegister(dOut_, cfg.latencyRead - 1)
      else dOut_
    }
  }

  impl(raw)

  def getPorts: Seq[memory.RawInterface] = Seq(raw)
}

class SimpleDualPortRawRAM(
    val cfg: memory.RawMemConfig
) extends Module
    with memory.RawMem {
  override val desiredName = "ChiselSimpleDualPortMem"

  assert(cfg.latencyRead >= 1)
  assert(cfg.latencyWrite >= 1)

  val rawRead = IO(
    new memory.RawInterface(cfg.wAddr, cfg.wData, true, false)
  )
  val rawWrite = IO(
    new memory.RawInterface(cfg.wAddr, cfg.wData, false, true)
  )

  private val numBytes =
    (cfg.wData >> 3) // NOTE: same as the write strobe width

  private val mem =
    SyncReadMem(1 << cfg.wAddr, Vec(numBytes, UInt(8.W)))
  private class WrReq(val wAddr: Int, val wData: Int) extends Bundle {
    val wStrobe = (wData >> 3)

    val addr = UInt(wAddr.W)
    val dIn = Bits(wData.W)
    val wstrb = UInt(wStrobe.W)
  }

  private val wrReq_ = Wire(new WrReq(wAddr = cfg.wAddr, wData = cfg.wData))
  wrReq_.addr := rawWrite.addr
  wrReq_.dIn := rawWrite.dIn
  wrReq_.wstrb := rawWrite.wstrb

  private val wrReqDelayed_ =
    if (cfg.latencyRead > 1) ShiftRegister(wrReq_, cfg.latencyWrite - 1)
    else wrReq_

  mem.write(
    wrReqDelayed_.addr,
    unpack(wrReqDelayed_.dIn, 8),
    wrReqDelayed_.wstrb.asBools
  )
  rawWrite.dOut := 0.U

  private val dOut_ = mem.read(rawRead.addr, true.B).asUInt

  rawRead.dOut := {
    if (cfg.latencyRead > 1) ShiftRegister(dOut_, cfg.latencyRead - 1)
    else dOut_
  }

  def getPorts: Seq[memory.RawInterface] = Seq(rawRead, rawWrite)
}

class TrueDualPortRawRAM(
    val cfg: memory.RawMemConfig
) extends Module
    with memory.RawMem {
  override val desiredName = "ChiselSimpleDualPortMem"

  assert(cfg.latencyRead >= 1)
  assert(cfg.latencyWrite >= 1)

  val raw1 = IO(
    new memory.RawInterface(cfg.wAddr, cfg.wData, true, true)
  )
  val raw2 = IO(
    new memory.RawInterface(cfg.wAddr, cfg.wData, true, true)
  )

  private val numBytes =
    (cfg.wData >> 3) // NOTE: same as the write strobe width

  private val mem =
    SyncReadMem(1 << cfg.wAddr, Vec(numBytes, UInt(8.W)))
  private class WrReq(val wAddr: Int, val wData: Int) extends Bundle {
    val wStrobe = (wData >> 3)

    val addr = UInt(wAddr.W)
    val dIn = Bits(wData.W)
    val wstrb = UInt(wStrobe.W)
  }

  private def impl(raw: memory.RawInterface) = {

    val wrReq_ = Wire(new WrReq(wAddr = cfg.wAddr, wData = cfg.wData))
    wrReq_.addr := raw.addr
    wrReq_.dIn := raw.dIn
    wrReq_.wstrb := raw.wstrb

    val wrReqDelayed_ =
      if (cfg.latencyRead > 1) ShiftRegister(wrReq_, cfg.latencyWrite - 1)
      else wrReq_

    mem.write(
      wrReqDelayed_.addr,
      unpack(wrReqDelayed_.dIn, 8),
      wrReqDelayed_.wstrb.asBools
    )
    raw.dOut := 0.U

    val dOut_ = mem.read(raw.addr, true.B).asUInt

    raw.dOut := {
      if (cfg.latencyRead > 1) ShiftRegister(dOut_, cfg.latencyRead - 1)
      else dOut_
    }
  }

  impl(raw1)
  impl(raw2)

  def getPorts: Seq[memory.RawInterface] = Seq(raw1, raw2)
}
