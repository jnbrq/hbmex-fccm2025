package chext.elastic

import chext.elastic

import chisel3._
import chisel3.util._
import chisel3.experimental.BundleLiterals._

import chiseltest._

import elastic._
import elastic.ConnectOp._
import elastic.test.PacketOps._

class MyModule extends Module {
  val in = IO(Source(Decoupled(new DataLast)))
  val out = IO(Sink(Decoupled(new DataLast)))

  SourceBuffer(in) :=> out
}

class BurstTest extends chext.test.FreeSpec {
  enableVcd()

  "BurstTest" in test(new MyModule) { dut =>
    {
      fork {
        dut.in.sendPacketBurst(
          Seq(
            TesterDataLast(0x0001, false),
            TesterDataLast(0x0003, false),
            TesterDataLast(0x0005, true)
          )
        )
      }.fork {
        println(dut.out.receivePacketBurst[TesterDataLast]())
      }.join()
    }
  }
}
