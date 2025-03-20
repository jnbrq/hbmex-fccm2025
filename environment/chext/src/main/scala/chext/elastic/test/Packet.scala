package chext.elastic.test

import chisel3._
import chisel3.util._
import chiseltest._

import chext.test.Expect

import scala.collection.mutable.ArrayBuffer

trait Packet {
  def last: Boolean
}

trait PacketTag[T] {
  def isLast(t: T): Boolean
}

object PacketTag {
  def makeTag[T <: Packet] = new PacketTag[T] {
    def isLast(t: T): Boolean = t.last
  }

  def makeTagPrimitive[T] = new PacketTag[T] {
    def isLast(t: T): Boolean = true
  }
}

abstract class PacketBridge[D <: Data, TP: PacketTag] {
  def toTester(t: D): TP
  def toLit(gen: D, tt: TP): D
}

trait PacketOps {
  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val tagInt = PacketTag.makeTagPrimitive[Int]

  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val tagLong = PacketTag.makeTagPrimitive[Long]

  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val tagBigInt = PacketTag.makeTagPrimitive[BigInt]

  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val tagBoolean = PacketTag.makeTagPrimitive[Boolean]

  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val bridgeUIntToInt = new PacketBridge[UInt, Int] {
    def toLit(gen: UInt, tt: Int): UInt = tt.asUInt
    def toTester(t: UInt): Int = t.litValue.toInt
  }

  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val bridgeUIntToLong = new PacketBridge[UInt, Long] {
    def toLit(gen: UInt, tt: Long): UInt = tt.asUInt
    def toTester(t: UInt): Long = t.litValue.toLong
  }

  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val bridgeUIntToBigInt = new PacketBridge[UInt, BigInt] {
    def toLit(gen: UInt, tt: BigInt): UInt = tt.asUInt
    def toTester(t: UInt): BigInt = t.litValue
  }

  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val bridgeSIntToInt = new PacketBridge[SInt, Int] {
    def toLit(gen: SInt, tt: Int): SInt = tt.asSInt
    def toTester(t: SInt): Int = t.litValue.toInt
  }

  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val bridgeSIntToLong = new PacketBridge[SInt, Long] {
    def toLit(gen: SInt, tt: Long): SInt = tt.asSInt
    def toTester(t: SInt): Long = t.litValue.toLong
  }

  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val bridgeSIntToBigInt = new PacketBridge[SInt, BigInt] {
    def toLit(gen: SInt, tt: BigInt): SInt = tt.asSInt
    def toTester(t: SInt): BigInt = t.litValue
  }

  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val bridgeBoolToBoolean = new PacketBridge[Bool, Boolean] {
    def toLit(gen: Bool, tt: Boolean): Bool = tt.asBool
    def toTester(t: Bool): Boolean = (t.litValue == 1)
  }

  implicit class rvUtilsGeneric[T <: Data](rv: ReadyValidIO[T]) {
    def dequeue(): T = {
      var result: Option[T] = None
      rv.ready.poke(true)
      fork
        .withRegion(Monitor) {
          rv.waitForValid()
          rv.valid.expect(true.B)
          result = Some(rv.bits.peek())
        }
        .joinAndStep()
      rv.ready.poke(false)
      result.get
    }
  }

  implicit class rvUtils[D <: Data](rv: ReadyValidIO[D]) {
    def receivePacketBurst[TP]()(implicit
        bridge: PacketBridge[D, TP],
        tag: PacketTag[TP]
    ): Seq[TP] = {
      val beatBuffer = ArrayBuffer.empty[TP]
      var done = false

      do {
        val beat = receivePacket()
        done = tag.isLast(beat)
        beatBuffer.addOne(beat)
      } while (!done)

      beatBuffer.toSeq
    }

    def receivePacket[TP]()(implicit
        bridge: PacketBridge[D, TP],
        tag: PacketTag[TP]
    ): TP = bridge.toTester(rv.dequeue())

    def expectPacketBurst[TP](tps: Seq[TP])(implicit
        bridge: PacketBridge[D, TP],
        tag: PacketTag[TP]
    ): Unit = tps.foreach { (tp) =>
      {
        require(tag.isLast(tps.last))
        Expect.equals(tp, receivePacket[TP](), "expectPacket")
      }
    }

    def expectPacket[TP](tp: TP)(implicit
        bridge: PacketBridge[D, TP],
        tag: PacketTag[TP]
    ): Unit = rv.expectDequeue(bridge.toLit(rv.bits.cloneType, tp))

    def sendPacketBurst[TP](
        tps: Seq[TP]
    )(implicit
        bridge: PacketBridge[D, TP],
        tag: PacketTag[TP]
    ): Unit = {
      require(tag.isLast(tps.last))
      tps.foreach { sendPacket(_) }
    }

    def sendPacket[TP](
        tp: TP
    )(implicit
        bridge: PacketBridge[D, TP],
        tag: PacketTag[TP]
    ): Unit = rv.enqueue(bridge.toLit(rv.bits.cloneType, tp))
  }
}

object PacketOps extends PacketOps
