package chext.amba.axi4.full.components

import chisel3._
import chisel3.util._

import chext.amba.axi4
/*
abstract class InterconnectTestTop extends chext.Module {}

object Interconnect_TB extends chext.TestBench {
  def emitDemux(numMasters: Int, name: String) = {

    // modulo is only good for simulation
    def decodeFn(x: UInt) = (x >> 12) % numMasters.U

    val demuxCfg = DemuxConfig(
      axi4.Config(
        wId = 4,
        wAddr = 32,
        wData = 32,
        read = true,
        write = true,
        lite = false
      ),
      numMasters,
      decodeFn,
      desiredName = Some(name)
    )

    emit(new Demux(demuxCfg))
  }

  def emitMux(numSlaves: Int, name: String) = {
    val muxCfg =
      MuxConfig(
        axi4.Config(
          wId = 4,
          wAddr = 32,
          wData = 32,
          read = true,
          write = true,
          lite = false
        ),
        numSlaves,
        desiredName = Some(name)
      )

    emit(new Mux(muxCfg))
  }

  emitDemux(4, "DemuxDut_1")
  emitMux(4, "MuxDut_1")
}
*/