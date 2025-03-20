package chext.amba.axi4.full.components

import chisel3._
import chisel3.util._
import chisel3.experimental.prefix

import chext.amba.axi4
import chext.elastic

import elastic.ConnectOp._
import axi4.Ops._
import chext.util.BitOps._

import helpers.{SteerLeft, SteerRight}

case class UpscaleConfig(
    val axiSlaveCfg: axi4.Config,
    val wDataMaster: Int,
    val readOffsetQueueLength: Int = 16,
    val writeOffsetQueueLength: Int = 16
) {
  require(axiSlaveCfg.wId == 0, "axiSlaveCfg.wId must be zero!")
  require(!axiSlaveCfg.lite, "axiSlaveCfg.lite must be false!")
  require(wDataMaster > axiSlaveCfg.wData, "wDataMaster must be > axiSlaveCfg.wData")

  require(wDataMaster >= 8)
  require(isPow2(wDataMaster))

  val wDataSlave = axiSlaveCfg.wData
  val wStrobeMaster = wDataMaster >> 3
  val wStrobeSlave = wDataSlave >> 3
  val wOffset = log2Ceil(wDataMaster) - log2Ceil(wDataSlave)
  val wAddr = axiSlaveCfg.wAddr
  val axiMasterCfg = axiSlaveCfg.copy(wData = wDataMaster)
}

class Upscale(val cfg: UpscaleConfig) extends Module {
  import cfg._

  val s_axi = IO(axi4.full.Slave(axiSlaveCfg))
  val m_axi = IO(axi4.full.Master(axiMasterCfg))

  private def implRead(): Unit = prefix("read") {
    val addressGenerator = Module(new AddressGenerator(log2Ceil(wDataMaster >> 3)))
    val offsetQueue = Module(new Queue(UInt(wOffset.W), readOffsetQueueLength))

    def implAR(): Unit = prefix("ar") {
      new elastic.Fork(s_axi.ar) {
        override protected def onFork: Unit = {
          new elastic.Transform(fork(), addressGenerator.source) {
            override protected def onTransform: Unit = {
              out.addr := in.addr
              out.len := in.len
              out.size := in.size
              out.burst := in.burst
            }
          }

          fork() :=> m_axi.ar
        }
      }

      new elastic.Transform(addressGenerator.sink, offsetQueue.io.enq) {
        protected def onTransform: Unit = {
          out := in.addr.dropLsbN(log2Ceil(wDataSlave >> 3))
        }
      }
    }

    def implR(): Unit = prefix("r") {
      val steerRight = Module(new SteerRight(wDataMaster, wDataSlave))

      new elastic.Join(s_axi.r) {
        override protected def onJoin: Unit = {
          val beat = join(m_axi.r)
          val offset = join(offsetQueue.io.deq)

          steerRight.dataIn := beat.data
          steerRight.offsetIn := offset

          out.data := steerRight.dataOut

          out.id := beat.id // must be zero
          out.resp := beat.resp
          out.user := beat.user
          out.last := beat.last
        }
      }
    }

    implAR()
    implR()
  }

  private def implWrite(): Unit = prefix("write") {
    val addressGenerator = Module(new AddressGenerator(log2Ceil(wDataMaster >> 3)))
    val offsetQueue = Module(new Queue(UInt(wOffset.W), writeOffsetQueueLength))

    def implAW(): Unit = prefix("aw") {
      new elastic.Fork(s_axi.aw) {
        override protected def onFork: Unit = {
          new elastic.Transform(fork(), addressGenerator.source) {
            override protected def onTransform: Unit = {
              out.addr := in.addr
              out.len := in.len
              out.size := in.size
              out.burst := in.burst
            }
          }

          fork() :=> m_axi.aw
        }
      }

      new elastic.Transform(addressGenerator.sink, offsetQueue.io.enq) {
        protected def onTransform: Unit = {
          out := in.addr.dropLsbN(log2Ceil(wDataSlave >> 3))
        }
      }
    }

    def implW(): Unit = prefix("w") {
      val steerLeft = Module(new SteerLeft(wDataSlave, wDataMaster))
      val steerLeftStrobe = Module(new SteerLeft(wStrobeSlave, wStrobeMaster))

      new elastic.Join(m_axi.w) {
        override protected def onJoin: Unit = {
          val beat = join(s_axi.w)
          val offset = join(offsetQueue.io.deq)

          steerLeft.dataIn := beat.data
          steerLeft.offsetIn := offset

          steerLeftStrobe.dataIn := beat.strb
          steerLeftStrobe.offsetIn := offset

          out.data := steerLeft.dataOut
          out.strb := steerLeftStrobe.dataOut
          out.last := beat.last
          out.user := beat.user
        }
      }
    }

    def implB(): Unit = prefix("b") {
      m_axi.b :=> s_axi.b
    }

    implAW()
    implW()
    implB()
  }

  if (axiSlaveCfg.read) implRead()
  if (axiSlaveCfg.write) implWrite()
}
