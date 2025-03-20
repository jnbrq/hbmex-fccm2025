package chext.elastic

import chext.elastic

import chisel3._
import chisel3.util._
import chisel3.experimental.BundleLiterals._

import chiseltest._

import elastic._
import elastic.ConnectOp._
import elastic.test.PacketOps._

class DemuxSpec extends chext.test.FreeSpec with chext.test.TestMixin {
  useVerilator()
  enableVcd()

  "elastic.Demux.NoBurst" in test(new Demux(UInt(32.W), 4)) { dut =>
    {
      val source = dut.io.source
      val sinks = dut.io.sinks
      val select = dut.io.select

      source.initSource()
      sinks.foreach { _.initSink() }
      select.initSource()

      fork {
        source.sendPacket(0xa0)
        source.sendPacket(0xb0)
        source.sendPacket(0xc0)
        source.sendPacket(0xd0)
      }.fork {
        select.sendPacket(0x0)
        select.sendPacket(0x1)
        select.sendPacket(0x2)
        select.sendPacket(0x3)
      }.fork {
        sinks(0).expectPacket(0xa0)
        sinks(1).expectPacket(0xb0)
        sinks(2).expectPacket(0xc0)
        sinks(3).expectPacket(0xd0)
      }.join()
    }
  }

  "elastic.Demux.NoBurst.Rand" in test(new Demux(UInt(32.W), 4)) { dut =>
    {
      val source = dut.io.source
      val sinks = dut.io.sinks
      val select = dut.io.select

      source.initSource()
      sinks.foreach { _.initSink() }
      select.initSource()

      val numBursts = 128
      val dataSeq = Array.fill(numBursts) { math.abs(rand.nextInt()) }
      val selectSeq = Array.fill(numBursts) { rand.nextInt(dut.n) }

      fork {
        dataSeq.foreach { x =>
          {
            source.sendPacket(x)
            stepRandom(16)
          }
        }
      }.fork {
        selectSeq.foreach { x =>
          {
            select.sendPacket(x)
            stepRandom(16)
          }
        }
      }.fork {
        selectSeq.map { sinks(_) }.zip(dataSeq).foreach { case (sink, data) =>
          sink.expectPacket(data)
        }
      }.join()
    }
  }

  "elastic.Demux.Burst" in test(
    new Demux(new DataLast, 4, (x: DataLast) => x.last)
  ) { dut =>
    {
      val source = dut.io.source
      val select = dut.io.select
      val sinks = dut.io.sinks

      source.initSource()
      sinks.foreach { _.initSink() }
      select.initSource()

      fork {
        source.sendPacket(TesterDataLast(0xa0, false))
        source.sendPacket(TesterDataLast(0xa1, false))
        source.sendPacket(TesterDataLast(0xa2, true))
        step(2)

        source.sendPacket(TesterDataLast(0xb0, false))
        source.sendPacket(TesterDataLast(0xb1, false))
        source.sendPacket(TesterDataLast(0xb2, true))
        step(2)

        source.sendPacket(TesterDataLast(0xc0, false))
        source.sendPacket(TesterDataLast(0xc1, false))
        source.sendPacket(TesterDataLast(0xc2, true))
        step(2)

        source.sendPacket(TesterDataLast(0xd0, false))
        source.sendPacket(TesterDataLast(0xd1, false))
        source.sendPacket(TesterDataLast(0xd2, true))
        step(2)
      }.fork {
        select.sendPacket(0x00)
        select.sendPacket(0x01)
        select.sendPacket(0x02)
        select.sendPacket(0x03)
      }.fork {
        sinks(0).expectPacket(TesterDataLast(0xa0, false))
        sinks(0).expectPacket(TesterDataLast(0xa1, false))
        sinks(0).expectPacket(TesterDataLast(0xa2, true))

        sinks(1).expectPacket(TesterDataLast(0xb0, false))
        sinks(1).expectPacket(TesterDataLast(0xb1, false))
        sinks(1).expectPacket(TesterDataLast(0xb2, true))

        sinks(2).expectPacket(TesterDataLast(0xc0, false))
        sinks(2).expectPacket(TesterDataLast(0xc1, false))
        sinks(2).expectPacket(TesterDataLast(0xc2, true))

        sinks(3).expectPacket(TesterDataLast(0xd0, false))
        sinks(3).expectPacket(TesterDataLast(0xd1, false))
        sinks(3).expectPacket(TesterDataLast(0xd2, true))
      }.join()
    }
  }

  "elastic.Demux.Burst.Rand" in test(
    new Demux(new DataLast, 16, (x: DataLast) => x.last)
  ) { dut =>
    {
      val numBursts = 100
      val maxBurstLength = 32

      val dataSeq = Array
        .fill(numBursts) {
          val burstLength = rand.nextInt(maxBurstLength) + 1
          Array.tabulate(burstLength) { case (i) =>
            TesterDataLast(math.abs(rand.nextInt()), i == burstLength - 1)
          }
        }
      val selectSeq = Array.fill(numBursts) { rand.nextInt(dut.n) }

      val source = dut.io.source
      val select = dut.io.select
      val sinks = dut.io.sinks

      source.initSource()
      sinks.foreach { _.initSink() }
      select.initSource()

      fork {
        dataSeq.flatten.foreach { x =>
          {
            source.sendPacket(x)
            stepRandom(16)
          }
        }
      }.fork {
        selectSeq.foreach { x =>
          {
            select.sendPacket(x)
            stepRandom(16)
          }
        }
      }.fork {
        selectSeq.map { sinks(_) }.zip(dataSeq).foreach {
          case (sink, data) => {
            data.foreach { sink.expectPacket(_) }
          }
        }
      }.join()
    }
  }
}
