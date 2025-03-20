package chext.elastic

import chext.amba.axi4
import chext.elastic

import chisel3._
import chiseltest._
import org.scalatest.freespec.AnyFreeSpec

import axi4.Casts._

class TestModule extends Module {
  val io = IO(new Bundle {
    val S_AXI = chext.amba.axi4.Slave(chext.amba.axi4.Config(wId = 0))
  })

  private val s_axi = io.S_AXI.asFull

  s_axi.ar.nodeq()
  s_axi.r.noenq()

  s_axi.aw.nodeq()
  s_axi.w.nodeq()
  s_axi.b.noenq()
}

class TestModuleTester extends AnyFreeSpec with ChiselScalatestTester {
  "TestModuleTester should run correctly" in {
    test(new TestModule).withAnnotations(Seq(VerilatorBackendAnnotation)) {
      dut =>
        {
          dut.clock.step(8)
        }
    }
  }
}
