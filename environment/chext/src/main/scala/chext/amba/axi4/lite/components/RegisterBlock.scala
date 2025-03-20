package chext.amba.axi4.lite.components

import chext.amba.axi4
import chext.elastic

import chisel3._
import chisel3.util._

import elastic._
import elastic.ConnectOp._

import axi4.Casts._
import axi4.lite.SlaveBuffer

/** Defines an AXI4-Lite register block.
  *
  * @note
  *   Register block assumes that the address is always data-width aligned.
  *
  * @note
  *   If a register with `bitWidth < dataWidth` is mapped, it still occupies a `dataWidth` space in
  *   the memory space.
  *
  * @note
  *   Unaligned transfers are ignored by clearing the least significant bits.
  *
  * @note
  *   Overlapping assignments are OK, only the last one is effective.
  *
  * @param wAddr
  *   Address width of the AXI4-Lite interface.
  * @param wData
  *   Data width of the AXI4-Lite interface.
  * @param wMask
  *   Mask width. Determines the size of the assigned address space, which is `pow2(wMask)`.
  */
class RegisterBlock(
    val wAddr: Int = 32,
    val wData: Int = 32,
    val wMask: Int = 4
) {

  require(chisel3.util.isPow2(wData))
  require(wMask <= 31, "the implementation supports only 31-bit masks")
  require(wMask >= (log2Ceil(wData) - 3))

  /** address increment */
  val addrIncr = wData / 8

  /** address space size */
  val sizeAddressSpace = (1 << wMask)

  /** corresponding AXI4-Lite configuration */
  val cfgAxi = axi4.Config(
    wAddr = wAddr,
    wData = wData,
    lite = true
  )

  /** slave AXI4-Lite interface
    */
  val s_axil = Wire(axi4.lite.Slave(cfgAxi))

  // NOTE: To avoid valid signal waiting for ready down the line.
  private val s_axil_ = SlaveBuffer(s_axil, axi4.BufferConfig.all(2))

  /** @note
    *   Use `BigInt` to support masks larger than 31-bits.
    */
  private var lastAddr_ = 0: Int
  private var addrMap_ =
    scala.collection.mutable.ListBuffer.empty[
      (
          Int,
          Int,
          () => Bits,
          (Bits /* WDATA */, Bits /* WSTRB */ ) => Unit,
          String
      )
    ]

  /** Rebases the RegisterBlock address, the start value is 0x00.
    *
    * @param addr
    *   New base address.
    */
  def base(addr: Int): Unit = { lastAddr_ = addr }

  /** Returns the next address.
    *
    * @return
    *   next address
    */
  def nextAddr = lastAddr_

  /** Assigns a new register to the current address and increments the next address by `addrIncr`.
    *
    * @param t
    *   Register to assign
    * @param read
    *   Read enable
    * @param write
    *   Write enable
    * @param desc
    *   Description
    *
    * @return
    *   Assigned address
    */
  def reg[T <: Data](
      t: T,
      read: Boolean = true,
      write: Boolean = true,
      desc: String = "<no description>"
  ): Int = {
    require(t.getWidth <= wData)
    val ret = lastAddr_
    lastAddr_ = lastAddr_ + addrIncr
    require(lastAddr_ <= sizeAddressSpace, "Address space is too small.")
    val readFn = if (read) () => t.asUInt else () => (-1).S(wData.W).asUInt
    val writeFn =
      if (write) (wdata: Bits, wstrb: Bits) => {
        t := axi4.util
          .writeStrobeLogic(t.asTypeOf(wdata), wdata, wstrb)
          .asTypeOf(t)
      }
      else (wdata: Bits, wstrb: Bits) => ()
    addrMap_.addOne((ret, lastAddr_ - 1, readFn, writeFn, desc))
    ret
  }

  /** Reserves a region in the RegisterBlock.
    *
    * @param size
    *   Size of the region
    * @param desc
    *   Description
    * @return
    *   Assigned address
    */
  def reserve(size: Int, desc: String = "<no description>"): Int = {
    val ret = lastAddr_
    if (size % addrIncr == 0)
      lastAddr_ = lastAddr_ + size
    else
      lastAddr_ = lastAddr_ + (size / addrIncr + 1) * addrIncr
    require(lastAddr_ <= sizeAddressSpace, "Address space is too small.")
    addrMap_.addOne((ret, lastAddr_ - 1, () => 0.U, (_, _) => (), desc))
    ret
  }

  /** Export the register map to a file.
    *
    * @param path
    *   File path to save
    */
  def saveRegisterMap(directory: String, name: String) = {
    val write = new java.io.PrintWriter(f"${directory}/${name}.csv")
    write.println(s"sep=,")
    write.println(s"startAddr, endAddr, desc")
    addrMap_.foreach { case (startAddr, endAddr, _, _, desc) =>
      write.println(f"0x$startAddr%08x, 0x$endAddr%08x, $desc")
    }
    write.close()
  }

  val mask = (-1).S(wMask.W).asUInt ^ (addrIncr - 1).U

  private val rdReq_ = Queue.irrevocable(s_axil_.ar, 1)

  // We need to place a queue of length 1 to be fully AXI-compliant
  // Otherwise, valid signal waits for the ready signal
  private val rdRespQueue_ = Module(new Queue(chiselTypeOf(s_axil_.r.bits), 1))
  private val rdResp_ = rdRespQueue_.io.enq
  rdRespQueue_.io.deq :=> s_axil_.r

  private val wrReq_ = Queue.irrevocable(s_axil_.aw, 1)
  private val wrReqData_ = Queue.irrevocable(s_axil_.w, 1)

  // Same as before
  private val wrRespQueue_ = Module(new Queue(chiselTypeOf(s_axil_.b.bits), 1))
  private val wrResp_ = wrRespQueue_.io.enq
  wrRespQueue_.io.deq :=> s_axil_.b

  rdReq_.nodeq()
  rdResp_.noenq()
  wrReq_.nodeq()
  wrReqData_.nodeq()
  wrResp_.noenq()

  /** Enqueues a read response.
    *
    * @param data
    *   Data of the response.
    * @param resp_flag
    *   Response flag.
    */
  private def do_rdResp(data: UInt, resp_flag: UInt): Unit = {
    assert(rdReq)

    rdReq_.deq()

    val resp = Wire(chiselTypeOf(rdResp_.bits))
    resp.data := data
    resp.resp := resp_flag
    rdResp_.enq(resp)
  }

  /** Enqueues a write response.
    *
    * @param resp_flag
    *   Response flag.
    */
  private def do_wrResp(resp_flag: UInt): Unit = {
    assert(wrReq)

    wrReq_.deq()
    wrReqData_.deq()

    val resp = Wire(chiselTypeOf(wrResp_.bits))
    resp.resp := resp_flag
    wrResp_.enq(resp)
  }

  /** `True` if there is an incoming read request */
  val rdReq: Bool = (rdReq_.valid && rdResp_.ready)

  /** address of the incoming read request */
  val rdAddr: UInt = rdReq_.bits.addr & mask

  /** accepts the incoming read request, returning the default values to the requester.
    */
  def rdOk(): Unit = {
    val data = Wire(UInt(wData.W))

    // default, in case no address matches
    data := (-1).S(wData.W).asUInt

    addrMap_.foreach {
      case (addr, _, readFn, _, _) => {
        when(addr.asUInt === rdAddr) {
          data := readFn()
        }
      }
    }

    rdOk(data)
  }

  /** accepts the incoming read request, returning the provided data as a response to the requester.
    *
    * @param data
    *   data to return.
    */
  def rdOk(data: Bits): Unit = {
    do_rdResp(data.asUInt, axi4.ResponseFlag.OKAY)
  }

  /** fails the read request with an error. */
  def rdError(): Unit = {
    do_rdResp((-1).S(wData.W).asUInt, axi4.ResponseFlag.SLVERR)
  }

  /** `True` if there is an incoming write request */
  val wrReq: Bool = wrReq_.valid && wrReqData_.valid && wrResp_.ready

  /** address of the incoming write request */
  val wrAddr: UInt = wrReq_.bits.addr & mask

  /** data corresponding to the incoming write request */
  val wrData: UInt = wrReqData_.bits.data

  /** write strobe of the incoming write request */
  val wrStrb: UInt = wrReqData_.bits.strb

  /** accepts the write request, performing the default action.
    */
  def wrOk(): Unit = {
    addrMap_.foreach {
      case (addr, _, _, writeFn, _) => {
        when(addr.asUInt === wrAddr) {
          writeFn(wrData, wrStrb)
        }
      }
    }
    do_wrResp(axi4.ResponseFlag.OKAY)
  }

  /** accepts the write request, does not do anything. */
  def wrDiscard(): Unit = {
    do_wrResp(axi4.ResponseFlag.OKAY)
  }

  /** fails the write request. */
  def wrError(): Unit = {
    do_wrResp(axi4.ResponseFlag.SLVERR)
  }
}
