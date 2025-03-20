package chext.ip.memory

import chisel3._
import chisel3.util._

import chiseltest._

import chext.amba.axi4

import axi4.Ops._
import axi4.full.test.PacketUtils._

class Axi4FullTestModule2 extends Module {
  val wAddr = 15
  val wData = 64

  private val axiCfg = axi4.Config(wId = 0, wAddr = wAddr, wData = wData)

  private val rawMemCfg = RawMemConfig(
    wAddr = wAddr - 3,
    wData = wData,
    latencyRead = 2,
    latencyWrite = 2
  )

  private val portCfg = PortConfig(
    numOutstandingRead = 4,
    numOutstandingWrite = 4
  )

  val s_axi = IO(axi4.full.Slave(axiCfg))
  val mem_read = IO(new ReadInterface(12, 64))

  private val s_axi_ = s_axi

  private val memory = Module(
    new TrueDualPortRAM(rawMemCfg, portCfg, portCfg.copy(arbiterFunc = () => new ReadOnlyArbiter))
  )
  private val axi4fullBridge = Module(new Axi4FullToReadWriteBridge(axiCfg))

  s_axi_ :=> axi4fullBridge.s_axi

  axi4fullBridge.read <> memory.read1
  axi4fullBridge.write <> memory.write1

  mem_read <> memory.read2

  memory.write2.req.noenq()
  memory.write2.resp.nodeq()
}

class Axi4FullToReadWriteBridgeSpec2 extends chext.test.FreeSpec with chext.test.TestMixin {
  Target.setCurrent(chisel.Target)

  // useVerilator()
  enableVcd()

  "chext.ip.memory.Axi4FullToReadWriteBridge2.Basic1" in test(new Axi4FullTestModule2) { dut =>
    {
      import axi4.full.test._

      val s_axi = dut.s_axi
      s_axi.initSlave()

      fork {
        s_axi.sendWriteAddress(AddressPacket(0, 0x000, 0, 3, 1))
        s_axi.sendWriteAddress(AddressPacket(0, 0x000, 0, 3, 1))
      }.fork {
        s_axi.sendWriteData(WriteDataPacket(0x0ead_beef_dead_beefL, 0x0f, false))
        s_axi.sendWriteData(WriteDataPacket(0x0ead_beef_dead_beefL, 0xf0, false))
      }.fork {
        println(s_axi.receiveWriteResponse())
        println(s_axi.receiveWriteResponse())
      }.join()

      fork {
        s_axi.sendReadAddress(AddressPacket(0, 0x000, 0, 2, 1))
      }.fork {
        val x = s_axi.receiveReadData()
        println(f"0x${x.data}%016x")
      }.join()
    }
  }
}
