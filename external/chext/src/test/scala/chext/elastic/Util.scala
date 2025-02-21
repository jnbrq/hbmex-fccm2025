package chext.elastic

import chext.amba.axi4
import chext.elastic

import chisel3._
import chisel3.util._

import chiseltest._

import chisel3.experimental.BundleLiterals._

import elastic.test.PacketOps._

class DataLast extends Bundle {
  val data = UInt(32.W)
  val last = Bool()
}

case class TesterDataLast(
    val data: Int,
    override val last: Boolean
) extends elastic.test.Packet

object TesterDataLast {
  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val tagTesterDataLast =
    elastic.test.PacketTag.makeTag[TesterDataLast]

  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val bridgeTesterDataLast =
    new elastic.test.PacketBridge[DataLast, TesterDataLast] {
      def toLit(gen: DataLast, tt: TesterDataLast): DataLast = gen.Lit(
        _.data -> tt.data.asUInt,
        _.last -> tt.last.asBool
      )

      def toTester(t: DataLast): TesterDataLast = TesterDataLast(
        t.data.litValue.toInt,
        t.last.litValue == 1
      )
    }
}
