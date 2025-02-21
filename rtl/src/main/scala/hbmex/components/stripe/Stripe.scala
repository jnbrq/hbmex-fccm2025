package hbmex.components.stripe

import chisel3._
import chisel3.util._

import chext.util.VecCustomNamed
import chext.util.BitOps._

import chext.elastic
import elastic.ConnectOp._

import chext.amba.axi4
import axi4.Ops._

case class StripeConfig(
    val numInterfaces: Int,
    val axiCfg: axi4.Config,
    val transformations: Seq[Seq[Int]]
) {
  val axiControlCfg = axi4.Config(wAddr = 10, wData = 32, lite = true)

  require(transformations.forall(_.length == axiCfg.wAddr))
}

private class AddressTransform(
    val wAddr: Int,
    val transformations: Seq[Seq[Int]]
) extends Module {
  private val wSelect = log2Ceil(transformations.length)

  val select = IO(Input(UInt(wSelect.W)))
  val in = IO(Input(UInt(wAddr.W)))
  val out = IO(Output(UInt(wAddr.W)))

  private val vec = VecInit(transformations.map { in.extract(_) })

  out := vec(select)
}

class Stripe(cfg: StripeConfig) extends Module {
  import cfg._

  val S_AXI_CONTROL = IO(axi4.Slave(axiControlCfg))

  val S_AXI = IO(VecCustomNamed.zeroExtended(numInterfaces, axi4.Slave(axiCfg)))
  val M_AXI = IO(VecCustomNamed.zeroExtended(numInterfaces, axi4.Master(axiCfg)))

  private val rSelect = RegInit(0.U(32.W))

  private val regBlock = new axi4.lite.components.RegisterBlock(
    axiControlCfg.wAddr,
    axiControlCfg.wData,
    axiControlCfg.wAddr
  )

  regBlock.base(0x0000)
  regBlock.reg(rSelect, true, true, "REG_SELECT")

  when(regBlock.rdReq) {
    regBlock.rdOk()
  }

  when(regBlock.wrReq) {
    regBlock.wrOk()
  }

  S_AXI_CONTROL.asLite :=> regBlock.s_axil

  def impl(s_axi: axi4.full.Interface, m_axi: axi4.full.Interface): Unit = {
    def implRead(): Unit = {
      val addressTransform = Module(new AddressTransform(axiCfg.wAddr, transformations))

      s_axi.ar :=> m_axi.ar

      addressTransform.in := s_axi.ar.bits.addr
      m_axi.ar.bits.addr := addressTransform.out

      addressTransform.select := rSelect

      m_axi.r :=> s_axi.r
    }

    def implWrite(): Unit = {
      val addressTransform = Module(new AddressTransform(axiCfg.wAddr, transformations))

      s_axi.aw :=> m_axi.aw

      addressTransform.in := s_axi.aw.bits.addr
      m_axi.aw.bits.addr := addressTransform.out

      addressTransform.select := rSelect

      s_axi.w :=> m_axi.w
      m_axi.b :=> s_axi.b
    }

    if (axiCfg.read)
      implRead()

    if (axiCfg.write)
      implWrite()
  }

  S_AXI
    .zip(M_AXI)
    .foreach { case (a, b) => impl(a.asFull, b.asFull) }
}

object EmitStripe extends App {
  val transformations = Seq(
    Seq(32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
    Seq(32, 31, 30, 29, 14, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 28, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
    Seq(32, 31, 30, 15, 14, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 29, 28, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
    Seq(32, 31, 16, 15, 14, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 30, 29, 28, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
    Seq(32, 17, 16, 15, 14, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 31, 30, 29, 28, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
    Seq(18, 17, 16, 15, 14, 27, 26, 25, 24, 23, 22, 21, 20, 19, 32, 31, 30, 29, 28, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,

    // for failsafe
    Seq(32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
    Seq(32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse
  )

  val stripeCfg = StripeConfig(
    2,
    axi4.Config(
      wId = 0,
      wAddr = 33,
      wData = 256,
      axi3Compat = true,
      hasQos = false,
      hasProt = false,
      hasCache = false,
      hasRegion = false,
      hasLock = false
    ),
    transformations
  )

  emitVerilog(new Stripe(stripeCfg))
}
