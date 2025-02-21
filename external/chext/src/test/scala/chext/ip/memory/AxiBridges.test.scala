package chext.ip.memory

import chisel3._
import chisel3.util._

import chiseltest._

import chext.amba.axi4

import axi4.Ops._

class Axi4FullTestModule extends Module {
  val wAddr = 8
  val wData = 32

  private val axiCfg = axi4.Config(wId = 4, wAddr = wAddr, wData = wData)

  private val rawMemCfg = RawMemConfig(
    wAddr = wAddr,
    wData = wData,
    latencyRead = 4,
    latencyWrite = 2
  )

  private val portCfg = PortConfig(
    numOutstandingRead = 4,
    numOutstandingWrite = 4
  )

  val s_axi = IO(axi4.full.Slave(axiCfg))
  private val s_axi_ = axi4.full.SlaveBuffer(s_axi, axi4.BufferConfig.all(2))

  private val memory = Module(new SinglePortRAM(rawMemCfg, portCfg))
  private val axi4fullBridge = Module(new Axi4FullToReadWriteBridge(axiCfg))

  s_axi_ :=> axi4fullBridge.s_axi

  // TODO: change <> with a better operator
  axi4fullBridge.read <> memory.read
  axi4fullBridge.write <> memory.write
}

class Axi4FullToReadWriteBridgeSpec extends chext.test.FreeSpec with chext.test.TestMixin {
  Target.setCurrent(chisel.Target)

  // useVerilator()
  enableVcd()

  "chext.ip.memory.Axi4FullToReadWriteBridge.Basic1" in test(new Axi4FullTestModule) { dut =>
    {
      import axi4.full.test._
      import axi4.full.test.PacketUtils._

      val s_axi = dut.s_axi
      s_axi.initSlave()

      fork {
        s_axi.sendWriteAddress(AddressPacket(8, 0x0000, 3, 2, 1))
      }.fork {
        s_axi.sendWriteData(WriteDataPacket(0x0ded_beef, 0xf, false))
        s_axi.sendWriteData(WriteDataPacket(0x1ded_beef, 0xf, false))
        s_axi.sendWriteData(WriteDataPacket(0x2ded_beef, 0xf, false))
        s_axi.sendWriteData(WriteDataPacket(0x3ded_beef, 0xf, true))
      }.fork {
        println(s_axi.receiveWriteResponse())

        s_axi.sendReadAddress(AddressPacket(0, 0x0000, 3, 2, 1))

        println(s_axi.receiveReadData())
        println(s_axi.receiveReadData())
        println(s_axi.receiveReadData())
        println(s_axi.receiveReadData())
      }.join()
    }
  }
}

class Axi4LiteTestModule extends Module {
  val wAddr = 8
  val wData = 32

  private val axiCfg = axi4.Config(wAddr = wAddr, wData = wData, lite = true)

  private val rawMemCfg = RawMemConfig(
    wAddr = wAddr,
    wData = wData,
    latencyRead = 4,
    latencyWrite = 2
  )

  private val portCfg = PortConfig(
    numOutstandingRead = 4,
    numOutstandingWrite = 4
  )

  val s_axil = IO(axi4.lite.Slave(axiCfg))
  private val s_axil_ = axi4.lite.SlaveBuffer(s_axil, axi4.BufferConfig.all(2))

  private val memory = Module(new SinglePortRAM(rawMemCfg, portCfg))
  private val axi4liteBridge = Module(new Axi4LiteToReadWriteBridge(axiCfg))

  s_axil_ :=> axi4liteBridge.s_axil

  // TODO: change <> with a better operator
  axi4liteBridge.read <> memory.read
  axi4liteBridge.write <> memory.write
}

class Axi4LiteToReadWriteBridgeSpec extends chext.test.FreeSpec with chext.test.TestMixin {
  Target.setCurrent(chisel.Target)

  // useVerilator()
  enableVcd()

  "chext.ip.memory.Axi4LiteToReadWriteBridge.Basic1" in test(new Axi4LiteTestModule) { dut =>
    {
      import axi4.lite.test._
      import axi4.lite.test.PacketUtils._

      val s_axil = dut.s_axil
      s_axil.initSlave()

      fork {
        s_axil.sendWriteAddress(AddressPacket(0x0000))
        s_axil.sendWriteAddress(AddressPacket(0x0004))
        s_axil.sendWriteAddress(AddressPacket(0x0008))
        s_axil.sendWriteAddress(AddressPacket(0x000c))
      }.fork {
        s_axil.sendWriteData(WriteDataPacket(0x0ded_beef))
        s_axil.sendWriteData(WriteDataPacket(0x1ded_beef))
        s_axil.sendWriteData(WriteDataPacket(0x2ded_beef))
        s_axil.sendWriteData(WriteDataPacket(0x3ded_beef))
      }.fork {
        println(s_axil.receiveWriteResponse())
        println(s_axil.receiveWriteResponse())
        println(s_axil.receiveWriteResponse())
        println(s_axil.receiveWriteResponse())

        fork {
          s_axil.sendReadAddress(AddressPacket(0x0000))
          s_axil.sendReadAddress(AddressPacket(0x0004))
          s_axil.sendReadAddress(AddressPacket(0x0008))
          s_axil.sendReadAddress(AddressPacket(0x000c))
        }.fork {
          println(s_axil.receiveReadData())
          println(s_axil.receiveReadData())
          println(s_axil.receiveReadData())
          println(s_axil.receiveReadData())
        }.join()
      }.join()
    }
  }
}

object XilinxEmitter extends App {
  class Axi4FullBram(val wAddr: Int = 8, val wData: Int = 32) extends Module {
    override val desiredName = f"Axi4FullBram_${wAddr}_${wData}"

    private val axiCfg = axi4.Config(wId = 4, wAddr = wAddr, wData = wData)

    private val rawMemCfg = RawMemConfig(
      wAddr = wAddr,
      wData = wData,
      latencyRead = 4,
      latencyWrite = 2
    )

    private val portCfg = PortConfig(
      numOutstandingRead = 4,
      numOutstandingWrite = 4
    )

    val s_axi = IO(axi4.Slave(axiCfg))
    private val s_axi_ = axi4.full.SlaveBuffer(s_axi.asFull, axi4.BufferConfig.all(2))

    private val memory = Module(new SinglePortRAM(rawMemCfg, portCfg))
    private val axi4fullBridge = Module(new Axi4FullToReadWriteBridge(axiCfg))

    s_axi_ :=> axi4fullBridge.s_axi

    // TODO: change <> with a better operator
    axi4fullBridge.read <> memory.read
    axi4fullBridge.write <> memory.write
  }

  Target.setCurrent(xilinx.Target)

  emitVerilog(new Axi4FullBram(8, 32), Array("--target-dir", "output/"))
  emitVerilog(new Axi4FullBram(8, 64), Array("--target-dir", "output/"))
  emitVerilog(new Axi4FullBram(12, 256), Array("--target-dir", "output/"))
}
