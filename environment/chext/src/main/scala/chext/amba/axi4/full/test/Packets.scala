package chext.amba.axi4.full.test

import chisel3._
import chisel3.util._
import chisel3.experimental.BundleLiterals._

import chext.elastic
import chext.amba.axi4.full.{
  Interface,
  AddressChannel,
  ReadDataChannel,
  WriteDataChannel,
  WriteResponseChannel
}
import chiseltest._

import chext.test.Expect

import elastic.test.{Packet, PacketTag, PacketBridge}
import elastic.test.PacketOps._

case class AddressPacket(
    val id: Int,
    val addr: Long,
    val len: Int,
    val size: Int = 7,
    val burst: Int = 1 /* INCR */
) extends Packet {
  val last: Boolean = true
}

case class ReadDataPacket(
    val id: Int,
    val data: BigInt,
    val last: Boolean
) extends Packet

case class WriteDataPacket(
    val data: BigInt,
    val strb: Long,
    val last: Boolean
) extends Packet

case class WriteResponsePacket(
    val id: Int
) extends Packet {
  val last: Boolean = false
}

trait PacketUtils {
  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val axi4_full_tagAddressPacket = PacketTag.makeTag[AddressPacket]

  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val axi4_full_tagReadDataPacket = PacketTag.makeTag[ReadDataPacket]

  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val axi4_full_tagWriteDataPacket = PacketTag.makeTag[WriteDataPacket]

  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val axi4_full_tagWriteResponsePacket =
    PacketTag.makeTag[WriteResponsePacket]

  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val axi4_full_bridgeAddressPacket =
    new PacketBridge[AddressChannel, AddressPacket] {
      def toTester(t: AddressChannel): AddressPacket =
        AddressPacket(
          t.id.litValue.toInt,
          t.addr.litValue.toLong,
          t.len.litValue.toInt,
          t.size.litValue.toInt,
          t.burst.litValue.toInt
        )

      def toLit(gen: AddressChannel, tt: AddressPacket): AddressChannel =
        gen.Lit(
          _.id -> tt.id.U,
          _.addr -> tt.addr.U,
          _.len -> tt.len.U,
          _.size -> tt.size.U,
          _.burst -> tt.burst.U,
          _.lock -> 0.U,
          _.cache -> 0.U,
          _.prot -> 0.U,
          _.qos -> 0.U,
          _.region -> 0.U
        )
    }

  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val axi4_full_bridgeReadDataPacket =
    new PacketBridge[ReadDataChannel, ReadDataPacket] {
      def toTester(t: ReadDataChannel): ReadDataPacket =
        ReadDataPacket(
          t.id.litValue.toInt,
          t.data.litValue,
          t.last.litValue == 1
        )

      def toLit(
          gen: ReadDataChannel,
          tt: ReadDataPacket
      ): ReadDataChannel =
        gen.Lit(
          _.id -> tt.id.U,
          _.data -> tt.data.U,
          _.last -> tt.last.B,
          _.resp -> 0.U
        )

    }

  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val axi4_full_bridgeWriteDataPacket =
    new PacketBridge[WriteDataChannel, WriteDataPacket] {
      def toTester(t: WriteDataChannel): WriteDataPacket =
        WriteDataPacket(
          t.data.litValue,
          t.strb.litValue.toLong,
          t.last.litValue == 1
        )

      def toLit(
          gen: WriteDataChannel,
          tt: WriteDataPacket
      ): WriteDataChannel =
        gen.Lit(
          _.data -> tt.data.U,
          _.last -> tt.last.B,
          _.strb -> tt.strb.U
        )

    }

  @annotation.nowarn /* suppress warning: Implicit definition should have explicit type */
  implicit val axi4_full_bridgeWriteResponsePacket =
    new PacketBridge[
      WriteResponseChannel,
      WriteResponsePacket
    ] {
      def toTester(t: WriteResponseChannel): WriteResponsePacket =
        WriteResponsePacket(
          t.id.litValue.toInt
        )

      def toLit(
          gen: WriteResponseChannel,
          tt: WriteResponsePacket
      ): WriteResponseChannel =
        gen.Lit(
          _.id -> tt.id.U,
          _.resp -> 0.U
        )

    }

  implicit class axi4_full_interface_packet_utils(interface: Interface) {
    def receiveReadAddress() = interface.ar.receivePacket[AddressPacket]()

    def expectReadAddress(id: Int, addr: Int, len: Int): Unit =
      expectReadAddress(AddressPacket(id, addr, len))

    def expectReadAddress(ar: AddressPacket): Unit =
      Expect.equals(
        ar,
        receiveReadAddress(),
        "expectReadAddress"
      )

    def sendReadAddress(id: Int, addr: Int, len: Int): Unit =
      sendReadAddress(AddressPacket(id, addr, len))

    def sendReadAddress(ar: AddressPacket): Unit =
      interface.ar.sendPacket(ar)

    def receiveReadData() =
      interface.r.receivePacket[ReadDataPacket]()

    def receiveReadDataBurst() =
      interface.r.receivePacketBurst[ReadDataPacket]()

    def expectReadData(id: Int, data: Long): Unit =
      expectReadData(ReadDataPacket(id, data, true))

    def expectReadData(r: ReadDataPacket): Unit =
      Expect.equals(
        r,
        interface.r.receivePacket[ReadDataPacket](),
        "expectReadData"
      )

    def expectReadDataBurst(beats: Seq[ReadDataPacket]): Unit =
      interface.r.expectPacketBurst(beats)

    def expectReadDataBurst(id: Int, data: Seq[Long]): Unit =
      expectReadDataBurst(data.zipWithIndex.map { case (x, n) =>
        ReadDataPacket(id, x, n == data.length - 1)
      })

    def sendReadData(id: Int, data: Long): Unit =
      sendReadData(ReadDataPacket(id, data, true))

    def sendReadData(r: ReadDataPacket): Unit =
      interface.r.sendPacket(r)

    def sendReadDataBurst(beats: Seq[ReadDataPacket]): Unit =
      interface.r.sendPacketBurst(beats)
    def sendReadDataBurst(id: Int, data: Seq[Long]): Unit =
      sendReadDataBurst(data.zipWithIndex.map { case (x, n) =>
        ReadDataPacket(id, x, n == data.length - 1)
      })

    def receiveWriteAddress() =
      interface.aw.receivePacket[AddressPacket]()

    def expectWriteAddress(id: Int, addr: Int, len: Int): Unit =
      expectWriteAddress(AddressPacket(id, addr, len))

    def expectWriteAddress(aw: AddressPacket): Unit =
      Expect.equals(
        aw,
        receiveWriteAddress(),
        "expectWriteAddress"
      )

    def sendWriteAddress(id: Int, addr: Int, len: Int): Unit =
      sendWriteAddress(AddressPacket(id, addr, len))

    def sendWriteAddress(aw: AddressPacket): Unit =
      interface.aw.sendPacket(aw)

    def receiveWriteData() =
      interface.w.receivePacket[WriteDataPacket]()

    def receiveWriteDataBurst() =
      interface.w.receivePacketBurst[WriteDataPacket]()

    def expectWriteData(w: WriteDataPacket): Unit =
      Expect.equals(
        w,
        interface.w.receivePacket[WriteDataPacket](),
        "expectWriteData"
      )

    def expectWriteDataBurst(beats: Seq[WriteDataPacket]): Unit =
      interface.w.expectPacketBurst(beats)

    def sendWriteData(w: WriteDataPacket): Unit =
      interface.w.sendPacket(w)

    def sendWriteDataBurst(beats: Seq[WriteDataPacket]): Unit =
      interface.w.sendPacketBurst(beats)

    def receiveWriteResponse() =
      interface.b.receivePacket[WriteResponsePacket]()

    def expectWriteResponse(id: Int): Unit =
      expectWriteResponse(WriteResponsePacket(id))

    def expectWriteResponse(b: WriteResponsePacket): Unit =
      Expect.equals(b, receiveWriteResponse(), "expectWriteResponse")

    def sendWriteResponse(id: Int): Unit =
      sendWriteResponse(WriteResponsePacket(id))

    def sendWriteResponse(b: WriteResponsePacket): Unit =
      interface.b.sendPacket(b)

    def initSlave(): Unit = {
      interface.ar.initSource()
      interface.r.initSink()

      interface.aw.initSource()
      interface.w.initSource()
      interface.b.initSink()
    }

    def initMaster(): Unit = {
      interface.ar.initSink()
      interface.r.initSource()

      interface.aw.initSink()
      interface.w.initSink()
      interface.b.initSource()
    }
  }
}

object PacketUtils extends PacketUtils
