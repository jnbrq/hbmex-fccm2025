package chext.ip.memory

import chisel3._
import chisel3.util._

case class PortConfig(
    val numOutstandingRead: Int = 4,
    val numOutstandingWrite: Int = 4,
    val arbiterFunc: ReadWriteArbiter.Func = ReadWriteArbiter.defaultFunc
) {
  assert(numOutstandingRead >= 1)
  assert(numOutstandingWrite >= 1)
}

class SinglePortRAM(
    val rawMemCfg: RawMemConfig,
    val portCfg: PortConfig = PortConfig()
) extends Module {
  import rawMemCfg._

  override val desiredName = f"${Target.current.name}SinglePortRAM"

  val read = IO(new ReadInterface(wAddr, wData))
  val write = IO(new WriteInterface(wAddr, wData))

  require(latencyRead >= 1)
  require(latencyWrite >= 1)

  private val rawMem = Module(Target.current.createSinglePortRawRAM(rawMemCfg))

  private val raw = rawMem.getPorts(0)

  private val bridge = Module(new ReadWriteToRawBridge(rawMemCfg, portCfg))

  // TODO: change <> with a better operator
  read <> bridge.read
  write <> bridge.write
  raw <> bridge.raw
}

class SimpleDualPortRAM(val rawMemCfg: RawMemConfig, val portCfg: PortConfig = PortConfig())
    extends Module {
  import rawMemCfg._

  override val desiredName = f"${Target.current.name}SimpleDualPortRAM"

  val read = IO(new ReadInterface(wAddr, wData))
  val write = IO(new WriteInterface(wAddr, wData))

  require(latencyRead >= 1)
  require(latencyWrite >= 1)

  private val rawMem = Module(Target.current.createSimpleDualPortRawRAM(rawMemCfg))

  private val rawRead =
    rawMem.getPorts.filter((x) => x.supportsRead && !x.supportsWrite)(0)
  private val rawWrite =
    rawMem.getPorts.filter((x) => !x.supportsRead && x.supportsWrite)(0)

  private val readBridge = Module(new ReadToRawBridge(rawMemCfg, portCfg))
  private val writeBridge = Module(new WriteToRawBridge(rawMemCfg, portCfg))

  // TODO: change <> with a better operator
  read <> readBridge.read
  write <> writeBridge.write
  rawRead <> readBridge.raw
  rawWrite <> writeBridge.raw
}

class TrueDualPortRAM(
    val rawMemCfg: RawMemConfig,
    val portCfg1: PortConfig = PortConfig(),
    val portCfg2: PortConfig = PortConfig()
) extends Module {
  import rawMemCfg._

  override val desiredName = f"${Target.current.name}TrueDualPortRAM"

  val read1 = IO(new ReadInterface(wAddr, wData))
  val read2 = IO(new ReadInterface(wAddr, wData))
  val write1 = IO(new WriteInterface(wAddr, wData))
  val write2 = IO(new WriteInterface(wAddr, wData))

  private val rawMem = Module(Target.current.createTrueDualPortRawRAM(rawMemCfg))

  private val raw1 = rawMem.getPorts(0)
  private val raw2 = rawMem.getPorts(1)

  private val bridge1 = Module(new ReadWriteToRawBridge(rawMemCfg, portCfg1))
  private val bridge2 = Module(new ReadWriteToRawBridge(rawMemCfg, portCfg2))

  // TODO: change <> with a better operator

  // first port
  read1 <> bridge1.read
  write1 <> bridge1.write
  raw1 <> bridge1.raw

  // second port
  read2 <> bridge2.read
  write2 <> bridge2.write
  raw2 <> bridge2.raw
}

object Emitter extends App {
  Target.setCurrent(xilinx.Target)

  emitVerilog(
    new SimpleDualPortRAM(RawMemConfig(256, 15, 8, 1), PortConfig(12, 12)),
    Array("--target-dir", "output/")
  )

  emitVerilog(
    new SinglePortRAM(RawMemConfig(256, 15, 8, 1), PortConfig(12, 12)),
    Array("--target-dir", "output/")
  )

  emitVerilog(
    new TrueDualPortRAM(RawMemConfig(256, 15, 8, 1), PortConfig(12, 12)),
    Array("--target-dir", "output/")
  )
}
