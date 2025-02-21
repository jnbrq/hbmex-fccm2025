package chext.amba.axi4.lite.components

import chisel3._
import chisel3.util._
import chisel3.experimental._
import chisel3.experimental.BundleLiterals._

import chiseltest._

import chext.amba.axi4
import axi4.lite.components.{InterconnectTester, InterconnectHelper}

class MuxSpec extends chext.test.FreeSpec {
  def moduleFn = new Mux(
    MuxConfig(
      axi4.Config(
        wAddr = 32,
        wData = 32,
        read = true,
        write = true,
        lite = true
      ),
      8
    )
  )

  enableVcd()
  useVerilator()

  implicit val helper: InterconnectHelper[Mux] =
    new InterconnectHelper[Mux] {
      def slaveInterfaces(module: Mux): Seq[axi4.lite.Interface] =
        module.s_axil.toSeq

      def masterInterfaces(module: Mux): Seq[axi4.lite.Interface] =
        Seq(module.m_axil)
    }

  "AXI4 Lite Mux (basic)" in test(moduleFn) {
    new InterconnectTester(_) {
      protected def createTasks(): Unit = {
        for (i <- (0 until 64)) {
          for (slaveIdx <- (0 until 8)) {
            readTask(slaveIdx, 0, (slaveIdx << 16))
            writeTask(slaveIdx, 0, (slaveIdx << 16))
          }
        }
      }
    }.run()
  }
}
