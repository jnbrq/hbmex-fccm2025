package chext.amba.axi4.full.components

import chisel3._
import chisel3.util._

import chext.elastic
import chext.amba.axi4

import elastic.ConnectOp._
import axi4.Ops._

case class ProtocolConverterConfig(
    val axiSlaveCfg: axi4.Config,
    val axiMasterCfg: axi4.Config,
    val slaveNeverBursts: Boolean = false
) {

  val wDataSlave = axiSlaveCfg.wData
  val wDataMaster = axiMasterCfg.wData

  /** Parallelism in the ID dimension. */
  val wIdEffective = Seq(axiSlaveCfg.wId, axiMasterCfg.wId).min

  val isPassthrough = {
    val cfg0 = axiSlaveCfg.copy(wId = 0, wAddr = 0)
    val cfg1 = axiMasterCfg.copy(wId = 0, wAddr = 0)

    val cond0 = cfg0 == cfg1
    val cond1 = axiMasterCfg.wId >= axiSlaveCfg.wId

    cond0 && cond1
  }

  val axiSlaveCfgInternal = axiSlaveCfg.copy(axi3Compat = false)
  val axiMasterCfgInternal = axiMasterCfg.copy(axi3Compat = false)

  val idDemuxCfg =
    if (wIdEffective > 0) Some(IdDemuxConfig(axiSlaveCfgInternal, wIdEffective))
    else None

  val idSerializeCfg =
    if (!isPassthrough && axiSlaveCfgInternal.wId != wIdEffective)
      Some(IdSerializeConfig(axiSlaveCfgInternal.copy(wId = axiSlaveCfg.wId - wIdEffective)))
    else
      None

  val upscaleCfg =
    if (wDataSlave < wDataMaster)
      Some(UpscaleConfig(axiSlaveCfgInternal.copy(wId = 0), wDataMaster))
    else
      None

  val unburst1Cfg =
    if ((wDataSlave > wDataMaster) && !slaveNeverBursts)
      Some(UnburstConfig(axiSlaveCfgInternal.copy(wId = 0)))
    else
      None

  val downscaleCfg =
    if (wDataSlave > wDataMaster)
      Some(DownscaleConfig(axiSlaveCfgInternal.copy(wId = 0), wDataMaster))
    else
      None

  val unburst2Cfg =
    if (axiMasterCfg.axi3Compat)
      Some(UnburstConfig(axiSlaveCfgInternal.copy(wId = 0, wData = wDataMaster)))
    else
      None

  val idMuxCfg =
    if (wIdEffective > 0)
      Some(IdMuxConfig(axiSlaveCfgInternal.copy(wId = 0, wData = wDataMaster), wIdEffective))
    else
      None
}

/** The idea of this class to programmatically connect a large number of sequentially arranged
  * components that expose AXI ports.
  *
  * @todo
  *   Why not generalize this idea once we have a connectable interface?
  */
private class AxiFullStages {
  private type Interface = axi4.full.Interface
  import scala.collection.mutable.ArrayBuffer

  private class Stage(val name: String) {
    val slaveInterfaces: ArrayBuffer[Interface] = ArrayBuffer.empty
    val masterInterfaces: ArrayBuffer[Interface] = ArrayBuffer.empty
  }

  private val stages: ArrayBuffer[Stage] = ArrayBuffer.empty
  private val masterInterfaces: ArrayBuffer[Interface] = ArrayBuffer.empty
  private val slaveInterfaces: ArrayBuffer[Interface] = ArrayBuffer.empty

  def newStage(stageName: String = ""): Unit = {
    stages.addOne(new Stage(stageName))
  }

  def addSlaveInterface(interface: Interface): Unit = {
    if (stages.isEmpty) {
      slaveInterfaces.addOne(interface)
    } else {
      stages.last.slaveInterfaces.addOne(interface)
    }
  }

  def addMasterInterface(interface: Interface): Unit = {
    if (stages.isEmpty) {
      masterInterfaces.addOne(interface)
    } else {
      stages.last.masterInterfaces.addOne(interface)
    }
  }

  def addSlaveInterfaces(interface: Seq[Interface]): Unit = {
    if (stages.isEmpty) {
      slaveInterfaces.addAll(interface)
    } else {
      stages.last.slaveInterfaces.addAll(interface)
    }
  }

  def addMasterInterfaces(interface: Seq[Interface]): Unit = {
    if (stages.isEmpty) {
      masterInterfaces.addAll(interface)
    } else {
      stages.last.masterInterfaces.addAll(interface)
    }
  }

  def connectAll(): Unit = {
    var currentStage = 0
    var currentMasterInterfaces = masterInterfaces.toSeq

    stages.foreach { stage =>
      {
        val currentSlaveInterfaces = stage.slaveInterfaces.toSeq
        assert(
          currentMasterInterfaces.length == currentSlaveInterfaces.length,
          f"Interface lengths do not match at stage $currentStage with name ${stage.name}! (${currentMasterInterfaces.length} != ${currentSlaveInterfaces.length})"
        )

        currentMasterInterfaces.zip(currentSlaveInterfaces).foreach {
          case (master, slave) => {
            master :=> slave
          }
        }

        currentMasterInterfaces = stage.masterInterfaces.toSeq

        currentStage += 1
      }
    }

    val currentSlaveInterfaces = slaveInterfaces.toSeq
    assert(
      currentMasterInterfaces.length == currentSlaveInterfaces.length,
      f"Interface lengths do not match on the master-side! (${currentMasterInterfaces.length} != ${currentSlaveInterfaces.length})"
    )

    currentMasterInterfaces.zip(currentSlaveInterfaces).foreach {
      case (master, slave) => {
        master :=> slave
      }
    }
  }
}

class ProtocolConverter(val cfg: ProtocolConverterConfig) extends Module {
  import cfg._

  val s_axi = IO(axi4.full.Slave(axiSlaveCfg))
  val m_axi = IO(axi4.full.Master(axiMasterCfg))

  if (isPassthrough) {
    s_axi :=> m_axi
  } else {
    val stages = new AxiFullStages

    val s_axi_internal = Wire(axi4.full.Interface(axiSlaveCfgInternal))
    val m_axi_internal = Wire(axi4.full.Interface(axiMasterCfgInternal))

    // drives the internal wire
    s_axi :=> s_axi_internal

    stages.addMasterInterface(s_axi_internal)
    stages.addSlaveInterface(m_axi_internal)

    idDemuxCfg.foreach { cfg =>
      {
        stages.newStage("idDemux")

        val module = Module(new IdDemux(cfg)).suggestName("idDemux")
        stages.addSlaveInterface(module.s_axi)
        stages.addMasterInterfaces(module.m_axi)
      }
    }

    idSerializeCfg.foreach { cfg =>
      {
        stages.newStage("idSerialize")

        Seq.tabulate(1 << wIdEffective) {
          case (index) => {
            val module = Module(new IdSerialize(cfg)).suggestName(f"idSerialize_$index")
            stages.addSlaveInterface(module.s_axi)
            stages.addMasterInterface(module.m_axi)
          }
        }
      }
    }

    upscaleCfg.foreach { cfg =>
      {
        stages.newStage("upscale")

        Seq.tabulate(1 << wIdEffective) {
          case (index) => {
            val module = Module(new Upscale(cfg)).suggestName(f"upscale_$index")
            stages.addSlaveInterface(module.s_axi)
            stages.addMasterInterface(module.m_axi)
          }
        }
      }
    }

    unburst1Cfg.foreach { cfg =>
      {
        stages.newStage("unburst1")

        Seq.tabulate(1 << wIdEffective) {
          case (index) => {
            val module =
              Module(new Unburst(cfg)).suggestName(f"unburst1_$index")
            stages.addSlaveInterface(module.s_axi)
            stages.addMasterInterface(module.m_axi)
          }
        }
      }
    }

    downscaleCfg.foreach { cfg =>
      {
        stages.newStage("downscale")

        Seq.tabulate(1 << wIdEffective) {
          case (index) => {
            val module =
              Module(new Downscale(cfg)).suggestName(f"downscale_$index")
            stages.addSlaveInterface(module.s_axi)
            stages.addMasterInterface(module.m_axi)
          }
        }
      }
    }

    unburst2Cfg.foreach { cfg =>
      {
        stages.newStage("unburst2")

        Seq.tabulate(1 << wIdEffective) {
          case (index) => {
            val module = Module(new Unburst(cfg)).suggestName(f"unburst2_$index")
            stages.addSlaveInterface(module.s_axi)
            stages.addMasterInterface(module.m_axi)
          }
        }
      }
    }

    idMuxCfg.foreach { cfg =>
      {
        stages.newStage("idMux")

        val module = Module(new IdMux(cfg))
        stages.addSlaveInterfaces(module.s_axi)
        stages.addMasterInterface(module.m_axi)
      }
    }

    // force connect to get around the checks of the usual AXI connection operator
    m_axi_internal.ar :=> m_axi.ar
    m_axi_internal.aw :=> m_axi.aw
    m_axi_internal.w :=> m_axi.w

    m_axi.r :=> m_axi_internal.r
    m_axi.b :=> m_axi_internal.b

    stages.connectAll()
  }
}

object EmitProtocolConverter extends App {
  val cfg1 = ProtocolConverterConfig(
    axi4.Config(wAddr = 32, wData = 32, wId = 8),
    axi4.Config(wAddr = 32, wData = 128, wId = 2)
  )
  emitVerilog(new ProtocolConverter(cfg1))

  val cfg2 = ProtocolConverterConfig(
    axi4.Config(wAddr = 32, wData = 128, wId = 0),
    axi4.Config(wAddr = 32, wData = 32, wId = 0)
  )
  emitVerilog(new ProtocolConverter(cfg2))

  val cfg3 = ProtocolConverterConfig(
    axi4.Config(wAddr = 32, wData = 128, wId = 2),
    axi4.Config(wAddr = 32, wData = 128, wId = 4)
  )
  emitVerilog(new ProtocolConverter(cfg3))

  val cfg4 = ProtocolConverterConfig(
    axi4.Config(wAddr = 32, wData = 128, wId = 4),
    axi4.Config(wAddr = 32, wData = 128, wId = 2)
  )
  emitVerilog(new ProtocolConverter(cfg4))
}
