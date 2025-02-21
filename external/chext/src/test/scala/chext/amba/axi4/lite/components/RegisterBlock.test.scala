package chext.amba.axi4.lite.components

import chisel3._
import chisel3.util._
import chiseltest._

import chisel3.experimental.prefix

import chext.test.Expect
import chext.amba.axi4

import axi4.lite.ConnectOp._
import axi4.lite.test.PacketUtils._

class RegisterBlockTestDevice extends Module {
  private val regBlock = prefix("regBlock") { new RegisterBlock(32, 32, 8) }
  
  val saxil = IO(axi4.lite.Slave(regBlock.cfgAxi))

  saxil :=> regBlock.s_axil

  private val reg1 = RegInit(0.U(32.W))
  private val reg2 = RegInit(0.U(32.W))

  regBlock.base(0x00)
  regBlock.reg(reg1, read = true, write = true)
  regBlock.reg(reg2, read = true, write = true)
  regBlock.reg(48.U, read = true, write = false)

  private val region1 = regBlock.reserve(64)

  when(regBlock.rdReq) {
    when(regBlock.rdAddr >= region1.U) {
      regBlock.rdOk(regBlock.rdAddr - region1.U)
    }.otherwise {
      regBlock.rdOk()
    }
  }

  when(regBlock.wrReq) {
    regBlock.wrOk()
  }
}

class RegisterBundleSpec extends chext.test.FreeSpec {
  "RegisterBlockTestDevice should perform correctly" in {
    test(new RegisterBlockTestDevice).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      {
        dut.saxil.ar.initSource()
        dut.saxil.r.initSink()
        dut.saxil.aw.initSource()
        dut.saxil.w.initSource()
        dut.saxil.b.initSink()

        fork {
          dut.saxil.sendReadAddress(24)
          dut.saxil.sendWriteAddress(0)
          dut.saxil.sendWriteData(0x0FEE_0000)
        }.fork {
          Expect.equals(dut.saxil.receiveReadData().data, 12)
          dut.saxil.receiveWriteResponse()
        }.join()

        fork {
          dut.saxil.sendReadAddress(0)
          dut.saxil.sendReadAddress(4)
          dut.saxil.sendReadAddress(8)
        }.fork {
          Expect.equals(dut.saxil.receiveReadData().data, 0x0FEE_0000)
          Expect.equals(dut.saxil.receiveReadData().data, 0)
          Expect.equals(dut.saxil.receiveReadData().data, 48)
        }.join()
      }
    }
  }
}
