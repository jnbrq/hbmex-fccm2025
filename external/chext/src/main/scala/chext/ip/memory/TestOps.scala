package chext.ip.memory

import chisel3._
import chisel3.util._
import chisel3.experimental.BundleLiterals._

import chiseltest._

import chext.elastic
import chext.test.Expect
import elastic.test.PacketOps._

import org.scalatest.Assertions

trait TestOps {
  implicit class read_interface_ops(read: ReadInterface) {
    def sendReq(addr: Int): Unit = read.req.enqueue(addr.U)

    def receiveResp(): Long = read.resp.dequeue().litValue.toLong

    def expectResp(data: Long) =
      Expect.equals(receiveResp(), data)
  }

  implicit class write_interface_ops(write: WriteInterface) {
    private val genWriteRequest = chiselTypeOf(write.req.bits)

    def sendReq(addr: Int, data: Long, wstrb: Long) =
      write.req.enqueue(
        genWriteRequest.Lit(
          _.addr -> addr.U,
          _.data -> data.U,
          _.strb -> wstrb.U
        )
      )

    def receiveResp(): Unit = write.resp.dequeue().litValue.toLong
  }
}

object TestOps extends TestOps
