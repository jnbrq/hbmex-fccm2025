package chext.ip.memory.xilinx

abstract sealed class ClockingMode(val str: String)

object ClockingMode {
  case object Common extends ClockingMode("common_clock")
  case object Independent extends ClockingMode("independent_clock")
}

abstract sealed class EccMode(val str: String)

object EccMode {
  case object None extends EccMode("no_ecc")
  case object Both extends EccMode("both_encode_and_decode")
  case object DecodeOnly extends EccMode("decode_only")
  case object EncodeOnly extends EccMode("encode_only")
}

class EccType(val str: String)

object EccType {
  case object None extends EccType("none")
  def apply(str: String) = new EccType(str)
}

abstract sealed class MemoryPrimitive(val str: String)

object MemoryPrimitive {
  case object Auto extends MemoryPrimitive("auto")
  case object Distributed extends MemoryPrimitive("distributed")
  case object Block extends MemoryPrimitive("block")
  case object Ultra extends MemoryPrimitive("ultra")
  case object Mixed extends MemoryPrimitive("mixed")
}

abstract sealed class RamDecomp(val str: String)

object RamDecomp {
  case object Auto extends RamDecomp("auto")
  case object Area extends RamDecomp("area")
  case object Power extends RamDecomp("power")
}

abstract sealed class ResetMode(val str: String)

object ResetMode {
  case object Sync extends ResetMode("SYNC")
  case object Async extends ResetMode("ASYNC")
}

abstract sealed class WakeupTime(val str: String)

object WakeupTime {
  case object DisableSleep extends WakeupTime("disable_sleep")
  case object UseSleepPin extends WakeupTime("use_sleep_pin")
}

abstract sealed class WriteMode(val str: String)

object WriteMode {
  case object NoChange extends WriteMode("no_change")
  case object ReadFirst extends WriteMode("read_first")
  case object WriteFirst extends WriteMode("write_first")
}
