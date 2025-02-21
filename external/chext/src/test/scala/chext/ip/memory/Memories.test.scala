package chext.ip.memory

import chisel3._
import chisel3.util._
import chisel3.experimental.BundleLiterals._

import chiseltest._

import TestOps._
import chext.test.Expect

class SinglePortRAMSpec extends chext.test.FreeSpec with chext.test.TestMixin {
  Target.setCurrent(chisel.Target)

  // useVerilator()
  enableVcd()

  def dut_Basic1 = {
    val rawMemCfg = RawMemConfig(10, 32, 4, 4)
    val portCfg = PortConfig(8, 8)
    new SinglePortRAM(rawMemCfg, portCfg)
  }

  def dut_Basic2 = {
    val rawMemCfg = RawMemConfig(10, 32, 4, 4)
    val portCfg = PortConfig(8, 8)
    new SinglePortRAM(rawMemCfg, portCfg)
  }

  def dut_LongLatency1 = {
    val rawMemCfg = RawMemConfig(10, 32, 32, 32)
    val portCfg = PortConfig(4, 4)
    new SinglePortRAM(rawMemCfg, portCfg)
  }

  def dut_LongLatency2 = {
    val rawMemCfg = RawMemConfig(10, 32, 16, 8)
    val portCfg = PortConfig(1, 1)
    new SinglePortRAM(rawMemCfg, portCfg)
  }

  def dut_Interleaved = {
    val rawMemCfg = RawMemConfig(10, 32, 1, 1)
    val portCfg = PortConfig(8, 8)
    new SinglePortRAM(rawMemCfg, portCfg)
  }

  val genWriteRequest = new WriteRequest(10, 32)
  def writeRequest(addr: BigInt, data: BigInt) =
    genWriteRequest.Lit(_.addr -> addr.U, _.data -> data.U, _.strb -> 15.U)

  "chext.ip.memory.SinglePortRAMSpec.Basic1" in
    test(dut_Basic1) { dut =>
      {
        val testSize = 128
        val addr = Seq.range(0, testSize)
        val data = addr.map { (x) => (x + 0xa0) + ((x + 0xb0) << 16) }

        dut.write.req.initSource()
        dut.write.resp.initSink()
        dut.read.req.initSource()
        dut.read.resp.initSink()

        fork {
          addr.zip(data).foreach {
            case (a, d) => {
              dut.write.sendReq(a, d, 0xf)
              stepRandom(16)
            }
          }
        }.fork {
          data.foreach { (x) => dut.write.receiveResp() }
        }.join()

        fork {
          addr.foreach { (a) =>
            {
              dut.read.sendReq(a)
              stepRandom(16)
            }
          }
        }.fork {
          data.foreach((d) => {
            dut.read.expectResp(d)
          })
        }.join()
      }
    }

  "chext.ip.memory.SinglePortRAMSpec.Basic2" in
    test(dut_Basic2) { dut =>
      {
        val testSize = 128
        val addr = Seq.range(0, testSize)
        val data = addr.map { (x) => (x + 0xa0) + ((x + 0xb0) << 16) }

        dut.write.req.initSource()
        dut.write.resp.initSink()
        dut.read.req.initSource()
        dut.read.resp.initSink()

        fork {
          addr.zip(data).foreach {
            case (a, d) => {
              dut.write.sendReq(a, d, 0xf)
            }
          }

        }.fork {
          data.foreach { (x) =>
            dut.write.receiveResp()
            stepRandom(16)
          }
        }.join()

        fork {
          addr.foreach { (a) =>
            {
              dut.read.sendReq(a)
            }
          }
        }.fork {
          data.foreach((d) => {
            dut.read.expectResp(d)
            stepRandom(16)
          })
        }.join()
      }
    }

  "chext.ip.memory.SinglePortRAMSpec.LongLatency1" in
    test(dut_LongLatency1) { dut =>
      {
        val testSize = 128
        val addr = Seq.range(0, testSize)
        val data = addr.map { (x) => (x + 0xa0) + ((x + 0xb0) << 16) }

        dut.write.req.initSource()
        dut.write.resp.initSink()
        dut.read.req.initSource()
        dut.read.resp.initSink()

        fork {
          addr.zip(data).foreach {
            case (a, d) => {
              dut.write.sendReq(a, d, 0xf)
            }
          }

        }.fork {
          data.foreach { (x) =>
            dut.write.receiveResp()
          }
        }.join()

        fork {
          addr.foreach { (a) =>
            {
              dut.read.sendReq(a)
            }
          }
        }.fork {
          data.foreach((d) => {
            dut.read.expectResp(d)
          })
        }.join()
      }
    }

  "chext.ip.memory.SinglePortRAMSpec.LongLatency2" in
    test(dut_LongLatency2) { dut =>
      {
        val testSize = 128
        val addr = Seq.range(0, testSize)
        val data = addr.map { (x) => ((x + 0xa0) + ((x + 0xb0) << 16)) }

        dut.write.req.initSource()
        dut.write.resp.initSink()
        dut.read.req.initSource()
        dut.read.resp.initSink()

        fork {
          addr.zip(data).foreach {
            case (a, d) => {
              dut.write.sendReq(a, d, 0xf)
            }
          }
        }.fork {
          data.foreach { (x) =>
            {
              dut.write.receiveResp()
            }
          }
        }.join()

        fork {
          addr.foreach { (a) =>
            {
              dut.read.sendReq(a)
            }
          }
        }.fork {
          data.foreach { (d) =>
            {
              dut.read.expectResp(d)
            }
          }
        }.join()
      }
    }

  "chext.ip.memory.SinglePortRAMSpec.Interleaved" in
    test(dut_Interleaved) { dut =>
      {
        val testSize = 128
        val addr = Seq.range(0, testSize)
        val data = addr.map { (x) => ((x + 0xa0) + ((x + 0xb0) << 16)) }

        dut.write.req.initSource()
        dut.write.resp.initSink()
        dut.read.req.initSource()
        dut.read.resp.initSink()

        fork {
          addr.zip(data).foreach {
            case (a, d) => {
              dut.write.sendReq(a, d, 0xf)
            }
          }
        }.fork {
          data.foreach { (d) =>
            {
              dut.write.receiveResp()
            }
          }
        }.fork {
          step(10)

          addr.zip(data).foreach {
            case (a, d) => {
              dut.read.sendReq(a)
            }
          }
        }.fork {
          data.foreach { (d) =>
            {
              dut.read.expectResp(d)
            }
          }
        }.join()
      }
    }

}

class SimpleDualPortRAMSpec extends chext.test.FreeSpec with chext.test.TestMixin {
  Target.setCurrent(chisel.Target)

  // useVerilator()
  enableVcd()

  def dut_Basic1 = {
    val rawMemCfg = RawMemConfig(10, 32, 4, 4)
    val portCfg = PortConfig(8, 8)
    new SimpleDualPortRAM(rawMemCfg, portCfg)
  }

  def dut_Basic2 = {
    val rawMemCfg = RawMemConfig(10, 32, 4, 4)
    val portCfg = PortConfig(8, 8)
    new SimpleDualPortRAM(rawMemCfg, portCfg)
  }

  def dut_LongLatency1 = {
    val rawMemCfg = RawMemConfig(10, 32, 32, 32)
    val portCfg = PortConfig(4, 4)
    new SimpleDualPortRAM(rawMemCfg, portCfg)
  }

  def dut_LongLatency2 = {
    val rawMemCfg = RawMemConfig(10, 32, 16, 8)
    val portCfg = PortConfig(1, 1)
    new SimpleDualPortRAM(rawMemCfg, portCfg)
  }

  def dut_Interleaved = {
    val rawMemCfg = RawMemConfig(10, 32, 1, 1)
    val portCfg = PortConfig(8, 8)
    new SimpleDualPortRAM(rawMemCfg, portCfg)
  }

  val genWriteRequest = new WriteRequest(10, 32)
  def writeRequest(addr: BigInt, data: BigInt) =
    genWriteRequest.Lit(_.addr -> addr.U, _.data -> data.U, _.strb -> 15.U)

  "chext.ip.memory.SimpleDualPortRAMSpec.Basic1" in
    test(dut_Basic1) { dut =>
      {
        val testSize = 128
        val addr = Seq.range(0, testSize)
        val data = addr.map { (x) => (x + 0xa0) + ((x + 0xb0) << 16) }

        dut.write.req.initSource()
        dut.write.resp.initSink()
        dut.read.req.initSource()
        dut.read.resp.initSink()

        fork {
          addr.zip(data).foreach {
            case (a, d) => {
              dut.write.sendReq(a, d, 0xf)
              stepRandom(16)
            }
          }

        }.fork {
          data.foreach { (x) => dut.write.receiveResp() }
        }.join()

        fork {
          addr.foreach { (a) =>
            {
              dut.read.sendReq(a)
              stepRandom(16)
            }
          }
        }.fork {
          data.foreach((d) => {
            dut.read.expectResp(d)
          })
        }.join()
      }
    }

  "chext.ip.memory.SimpleDualPortRAMSpec.Basic2" in
    test(dut_Basic2) { dut =>
      {
        val testSize = 128
        val addr = Seq.range(0, testSize)
        val data = addr.map { (x) => (x + 0xa0) + ((x + 0xb0) << 16) }

        dut.write.req.initSource()
        dut.write.resp.initSink()
        dut.read.req.initSource()
        dut.read.resp.initSink()

        fork {
          addr.zip(data).foreach {
            case (a, d) => {
              dut.write.sendReq(a, d, 0xf)
            }
          }

        }.fork {
          data.foreach { (x) =>
            dut.write.receiveResp()
            stepRandom(16)
          }
        }.join()

        fork {
          addr.foreach { (a) =>
            {
              dut.read.sendReq(a)
            }
          }
        }.fork {
          data.foreach((d) => {
            dut.read.expectResp(d)
            stepRandom(16)
          })
        }.join()
      }
    }

  "chext.ip.memory.SimpleDualPortRAMSpec.LongLatency1" in
    test(dut_LongLatency1) { dut =>
      {
        val testSize = 128
        val addr = Seq.range(0, testSize)
        val data = addr.map { (x) => (x + 0xa0) + ((x + 0xb0) << 16) }

        dut.write.req.initSource()
        dut.write.resp.initSink()
        dut.read.req.initSource()
        dut.read.resp.initSink()

        fork {
          addr.zip(data).foreach {
            case (a, d) => {
              dut.write.sendReq(a, d, 0xf)
            }
          }

        }.fork {
          data.foreach { (x) =>
            dut.write.receiveResp()
          }
        }.join()

        fork {
          addr.foreach { (a) =>
            {
              dut.read.sendReq(a)
            }
          }
        }.fork {
          data.foreach((d) => {
            dut.read.expectResp(d)
          })
        }.join()
      }
    }

  "chext.ip.memory.SimpleDualPortRAMSpec.LongLatency2" in
    test(dut_LongLatency2) { dut =>
      {
        val testSize = 128
        val addr = Seq.range(0, testSize)
        val data = addr.map { (x) => ((x + 0xa0) + ((x + 0xb0) << 16)) }

        dut.write.req.initSource()
        dut.write.resp.initSink()
        dut.read.req.initSource()
        dut.read.resp.initSink()

        fork {
          addr.zip(data).foreach {
            case (a, d) => {
              dut.write.sendReq(a, d, 0xf)
            }
          }
        }.fork {
          data.foreach { (x) =>
            {
              dut.write.receiveResp()
            }
          }
        }.join()

        fork {
          addr.foreach { (a) =>
            {
              dut.read.sendReq(a)
            }
          }
        }.fork {
          data.foreach { (d) =>
            {
              dut.read.expectResp(d)
            }
          }
        }.join()
      }
    }

  "chext.ip.memory.SimpleDualPortRAMSpec.Interleaved" in
    test(dut_Interleaved) { dut =>
      {
        val testSize = 128
        val addr = Seq.range(0, testSize)
        val data = addr.map { (x) => ((x + 0xa0) + ((x + 0xb0) << 16)) }

        dut.write.req.initSource()
        dut.write.resp.initSink()
        dut.read.req.initSource()
        dut.read.resp.initSink()

        fork {
          addr.zip(data).foreach {
            case (a, d) => {
              dut.write.sendReq(a, d, 0xf)
            }
          }
        }.fork {
          data.foreach { (d) =>
            {
              dut.write.receiveResp()
            }
          }
        }.fork {
          step(10)

          addr.zip(data).foreach {
            case (a, d) => {
              dut.read.sendReq(a)
            }
          }
        }.fork {
          data.foreach { (d) =>
            {
              dut.read.expectResp(d)
            }
          }
        }.join()
      }
    }

}
