package chext.ip.memory.xilinx

import chext.ip.memory

import chisel3._
import chisel3.util._
import chisel3.experimental.noPrefix

case class xpm_memory_tdpram_config(
    val addrWidthA: Int = 6,
    val addrWidthB: Int = 6,
    val autoSleepTime: Int = 0,
    val byteWriteWidthA: Int = 32,
    val byteWriteWidthB: Int = 32,
    val cascadeHeight: Int = 0,
    val clockingMode: ClockingMode = ClockingMode.Independent,
    val eccBitRange: String = "7:0",
    val eccMode: EccMode = EccMode.None,
    val eccType: EccType = EccType.None,
    val ignoreInitSynth: Boolean = false,
    val memoryInitFile: String = "none",
    val memoryInitParam: String = "",
    val memoryOptimization: Boolean = true,
    val memoryPrimitive: MemoryPrimitive = MemoryPrimitive.Auto,
    val memorySize: Int = 2048,
    val messageControl: Boolean = false,
    val ramDecomp: RamDecomp = RamDecomp.Auto,
    val readDataWidthA: Int = 32,
    val readDataWidthB: Int = 32,
    val readLatencyA: Int = 2,
    val readLatencyB: Int = 2,
    val readResetValueA: String = "0",
    val readResetValueB: String = "0",
    val rstModeA: ResetMode = ResetMode.Sync,
    val rstModeB: ResetMode = ResetMode.Sync,
    val simAssertChk: Boolean = false,
    val useEmbeddedConstraint: Boolean = true,
    val useMemInit: Boolean = true,
    val useMemInitMmi: Boolean = false,
    val wakeupTime: WakeupTime = WakeupTime.DisableSleep,
    val writeDataWidthA: Int = 32,
    val writeDataWidthB: Int = 32,
    val writeModeA: WriteMode = WriteMode.NoChange,
    val writeModeB: WriteMode = WriteMode.NoChange,
    val writeProtect: Boolean = true
) {
  val writeEnabledWidthA = writeDataWidthA / byteWriteWidthA
  val writeEnabledWidthB = writeDataWidthB / byteWriteWidthB

  def toParams: Map[String, chisel3.experimental.Param] = {
    import chisel3.experimental.{Param, IntParam, StringParam}

    // NOTE: Commented out variables are not present in Xilinx 2022.2
    Map(
      "ADDR_WIDTH_A" -> IntParam(addrWidthA),
      "ADDR_WIDTH_B" -> IntParam(addrWidthB),
      "AUTO_SLEEP_TIME" -> IntParam(autoSleepTime),
      "BYTE_WRITE_WIDTH_A" -> IntParam(byteWriteWidthA),
      "BYTE_WRITE_WIDTH_B" -> IntParam(byteWriteWidthB),
      "CASCADE_HEIGHT" -> IntParam(cascadeHeight),
      "CLOCKING_MODE" -> StringParam(clockingMode.str),
      // "ECC_BIT_RANGE" -> StringParam(eccBitRange),
      // "ECC_MODE" -> StringParam(eccMode.str),
      "ECC_TYPE" -> StringParam(eccType.str),
      // "IGNORE_INIT_SYNTH" -> IntParam(if (ignoreInitSynth) 1 else 0),
      "MEMORY_INIT_FILE" -> StringParam(memoryInitFile),
      "MEMORY_INIT_PARAM" -> StringParam(memoryInitParam),
      "MEMORY_OPTIMIZATION" -> StringParam(
        if (memoryOptimization) "true" else "false"
      ),
      "MEMORY_PRIMITIVE" -> StringParam(memoryPrimitive.str),
      "MEMORY_SIZE" -> IntParam(memorySize),
      "MESSAGE_CONTROL" -> IntParam(if (messageControl) 1 else 0),
      "READ_DATA_WIDTH_A" -> IntParam(readDataWidthA),
      "READ_DATA_WIDTH_B" -> IntParam(readDataWidthB),
      "READ_LATENCY_A" -> IntParam(readLatencyA),
      "READ_LATENCY_B" -> IntParam(readLatencyB),
      "READ_RESET_VALUE_A" -> StringParam(readResetValueA),
      "READ_RESET_VALUE_B" -> StringParam(readResetValueB),
      "RST_MODE_A" -> StringParam(rstModeA.str),
      "RST_MODE_B" -> StringParam(rstModeB.str),
      "SIM_ASSERT_CHK" -> IntParam(if (simAssertChk) 1 else 0),
      "USE_EMBEDDED_CONSTRAINT" -> IntParam(
        if (useEmbeddedConstraint) 1 else 0
      ),
      "USE_MEM_INIT" -> IntParam(if (useMemInit) 1 else 0),
      "USE_MEM_INIT_MMI" -> IntParam(if (useMemInitMmi) 1 else 0),
      "WAKEUP_TIME" -> StringParam(wakeupTime.str),
      "WRITE_DATA_WIDTH_A" -> IntParam(writeDataWidthA),
      "WRITE_DATA_WIDTH_B" -> IntParam(writeDataWidthB),
      "WRITE_MODE_A" -> StringParam(writeModeA.str),
      "WRITE_MODE_B" -> StringParam(writeModeB.str),
      "WRITE_PROTECT" -> IntParam(if (writeProtect) 1 else 0)
    )
  }
}

class xpm_memory_tdpram(cfg: xpm_memory_tdpram_config)
    extends BlackBox(cfg.toParams) {
  val io = IO(new Bundle {
    val addra = Input(UInt(cfg.addrWidthA.W))
    val addrb = Input(UInt(cfg.addrWidthB.W))
    val clka = Input(Bool())
    val clkb = Input(Bool())
    val dbiterra = Output(Bool())
    val dbiterrb = Output(Bool())
    val dina = Input(Bits(cfg.writeDataWidthA.W))
    val dinb = Input(Bits(cfg.writeDataWidthB.W))
    val douta = Output(Bits(cfg.readDataWidthA.W))
    val doutb = Output(Bits(cfg.readDataWidthB.W))
    val ena = Input(Bool())
    val enb = Input(Bool())
    val injectdbiterra = Input(Bool())
    val injectdbiterrb = Input(Bool())
    val injectsbiterra = Input(Bool())
    val injectsbiterrb = Input(Bool())
    val regcea = Input(Bool())
    val regceb = Input(Bool())
    val rsta = Input(Bool())
    val rstb = Input(Bool())
    val sbiterra = Output(Bool())
    val sbiterrb = Output(Bool())
    val sleep = Input(Bool())
    val wea = Input(Bits((cfg.writeEnabledWidthA.W)))
    val web = Input(Bits((cfg.writeEnabledWidthB.W)))
  })
}

class TrueDualPortRawMem(
    val cfg: memory.RawMemConfig
) extends Module
    with memory.RawMem {
  assert(cfg.latencyWrite == 1)

  override val desiredName = "XilinxTrueDualPortRawMem"

  val interface1 = IO(new memory.RawInterface(cfg.wAddr, cfg.wData, true, true))
  val interface2 = IO(new memory.RawInterface(cfg.wAddr, cfg.wData, true, true))

  private val xpm_mem_cfg = xpm_memory_tdpram_config(
    addrWidthA = cfg.wAddr,
    addrWidthB = cfg.wAddr,
    byteWriteWidthA = 8,
    byteWriteWidthB = 8,
    memorySize = (cfg.wData << cfg.wAddr),
    readDataWidthA = cfg.wData,
    readDataWidthB = cfg.wData,
    readLatencyA = cfg.latencyRead,
    readLatencyB = cfg.latencyRead,
    writeDataWidthA = cfg.wData,
    writeDataWidthB = cfg.wData,
    useEmbeddedConstraint = false
  )

  private val xpm_mem = Module(new xpm_memory_tdpram(xpm_mem_cfg))

  xpm_mem.io.addra := interface1.addr
  xpm_mem.io.addrb := interface2.addr
  xpm_mem.io.clka := clock.asBool
  xpm_mem.io.clkb := clock.asBool
  xpm_mem.io.dina := interface1.dIn
  xpm_mem.io.dinb := interface2.dIn
  interface1.dOut := xpm_mem.io.douta
  interface2.dOut := xpm_mem.io.doutb
  xpm_mem.io.ena := true.B
  xpm_mem.io.enb := true.B
  xpm_mem.io.injectdbiterra := false.B
  xpm_mem.io.injectdbiterrb := false.B
  xpm_mem.io.injectsbiterra := false.B
  xpm_mem.io.injectsbiterrb := false.B
  xpm_mem.io.regcea := true.B
  xpm_mem.io.regceb := true.B
  xpm_mem.io.rsta := reset.asBool
  xpm_mem.io.rstb := reset.asBool
  xpm_mem.io.sleep := false.B
  xpm_mem.io.wea := interface1.wstrb
  xpm_mem.io.web := interface2.wstrb

  def getPorts: Seq[memory.RawInterface] = Seq(interface1, interface2)
}
