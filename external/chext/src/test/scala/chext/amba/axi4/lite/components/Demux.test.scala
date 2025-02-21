package chext.amba.axi4.lite.components

import chisel3._
import chisel3.util._
import chisel3.experimental._
import chisel3.experimental.BundleLiterals._

import chiseltest._

import chext.amba.axi4
import axi4.lite.components.{InterconnectTester, InterconnectHelper}

class DemuxSpec extends chext.test.FreeSpec {
  val numMasters = 4
  assert(isPow2(numMasters))

  def decodeFn(x: UInt) = (x >> 12) & (numMasters - 1).U
  def encodeFn(masterIdx: Int, offset: Int) = {
    ((masterIdx << 12) | offset)
  }

  def moduleFn = new Demux(
    DemuxConfig(
      chext.amba.axi4.Config(
        wAddr = 32,
        wData = 32,
        read = true,
        write = true,
        lite = true
      ),
      numMasters,
      decodeFn
    )
  )

  enableVcd()
  useVerilator()

  implicit val helper: InterconnectHelper[Demux] =
    new InterconnectHelper[Demux] {
      def slaveInterfaces(module: Demux): Seq[axi4.lite.Interface] =
        Seq(module.s_axil)

      def masterInterfaces(module: Demux): Seq[axi4.lite.Interface] =
        module.m_axil.toSeq
    }

  "AXI4 Lite Demux (basic)" in test(moduleFn) {
    new InterconnectTester(_, false) {
      protected def createTasks(): Unit = {
        for (i <- (0 until 16)) {
          for (masterIdx <- (0 until numMasters)) {
            readTask(0, masterIdx, encodeFn(masterIdx, rand.nextInt(32) << 5))
            writeTask(0, masterIdx, encodeFn(masterIdx, rand.nextInt(32) << 5))
          }
        }
      }
    }.run()
  }
}
