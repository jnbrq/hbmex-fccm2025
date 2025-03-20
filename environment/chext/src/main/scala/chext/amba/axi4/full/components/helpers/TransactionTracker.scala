package chext.amba.axi4.full.components.helpers

import chisel3._
import chisel3.util._

/** Manages (1) the number of outstanding requests, (2) the port that a thread is associated with.
  *
  * @param wIdTracked
  * @param wOutstanding
  */
class TransactionTracker(
    val wIdTracked: Int,
    val wPort: Int,
    val wOutstanding: Int
) extends Module {
  require(wIdTracked >= 0)
  require(wPort >= 0)
  require(wOutstanding >= 0)

  class IdCountPort extends Bundle {
    val id = Input(UInt(wIdTracked.W))
    val count = Output(UInt(wOutstanding.W))
    val port = Output(UInt(wPort.W))
  }

  class EnId extends Bundle {
    val en = Input(Bool())
    val id = Input(UInt(wIdTracked.W))
  }

  class EnIdPort extends Bundle {
    val en = Input(Bool())
    val id = Input(UInt(wIdTracked.W))
    val port = Input(UInt(wPort.W))
  }

  val io = IO(new Bundle {
    val initiate = new EnIdPort
    val complete = new EnId
    val query = new IdCountPort
  })

  def noQuery() = {
    io.query.id := DontCare
  }

  def noComplete() = {
    io.complete.en := false.B
    io.complete.id := DontCare
  }

  def complete(id: UInt) = {
    io.complete.en := true.B
    io.complete.id := id
  }

  def noInitiate() = {
    io.initiate.en := false.B
    io.initiate.id := DontCare
    io.initiate.port := DontCare
  }

  def initiate(id: UInt, port: UInt) = {
    io.initiate.en := true.B
    io.initiate.id := id
    io.initiate.port := port
  }

  def getCountPort(id: UInt): (UInt, UInt) = {
    io.query.id := id
    (io.query.count, io.query.port)
  }

  def canInitiate(id: UInt, port: UInt): Bool = {
    val (count_, port_) = getCountPort(id)
    count_ === 0.U || port_ === port
  }

  private val outstandingMax = (-1).S(wOutstanding.W).asUInt
  private val numIds = 1 << wIdTracked
  private val tableNumOutstanding = RegInit(
    VecInit( //
      Seq.fill(numIds) {
        0.U(wOutstanding.W)
      }
    )
  )
  private val tablePort = RegInit(
    VecInit(Seq.fill(numIds) { 0.U(wPort.W) })
  )

  when(io.initiate.en) {
    tablePort(io.initiate.id) := io.initiate.port
  }

  when(io.initiate.id =/= io.complete.id) {
    when(io.initiate.en) {
      tableNumOutstanding(io.initiate.id) :=
        tableNumOutstanding(io.initiate.id) + 1.U
    }

    when(io.complete.en) {
      tableNumOutstanding(io.complete.id) :=
        tableNumOutstanding(io.complete.id) - 1.U
    }
  }.otherwise {
    when(io.initiate.en && !io.complete.en) {
      tableNumOutstanding(io.initiate.id) :=
        tableNumOutstanding(io.initiate.id) + 1.U
    }.elsewhen(!io.initiate.en && io.complete.en) {
      tableNumOutstanding(io.initiate.id) :=
        tableNumOutstanding(io.initiate.id) - 1.U
    }
  }

  io.query.count := tableNumOutstanding(io.query.id)
  io.query.port := tablePort(io.query.id)
}
