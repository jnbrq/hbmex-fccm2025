package hbmex.components.stream

import chisel3._
import chisel3.util._

import chext.elastic
import elastic.DataLast

import chext.amba.axi4.full.components.helpers.SteerRight

case class DownsizeConfig(
    val wDataSource: Int,
    val wDataSink: Int
) {
  require(isPow2(wDataSink))
  require(isPow2(wDataSource))
  require(wDataSource >= wDataSink)
}

class Downsize(cfg: DownsizeConfig) extends Module {
  import cfg._

  val genSource = UInt(wDataSource.W)
  val genSink = UInt(wDataSink.W)

  val source = IO(elastic.Source(genSource))
  val sink = IO(elastic.Sink(genSink))

  private val steerRight = Module(new SteerRight(wDataSource, wDataSink))
  private val offset = RegInit(0.U(steerRight.wOffset.W))
  private val nextOffset = offset + 1.U

  new elastic.Arrival(source, sink) {
    steerRight.dataIn := in
    out := steerRight.dataOut

    steerRight.offsetIn := offset

    protected def onArrival: Unit = {
      produce()

      offset := nextOffset

      when(nextOffset === 0.U) {
        consume()
      }
    }
  }
}

class DownsizeWithLast(cfg: DownsizeConfig) extends Module {
  import cfg._

  val genSource = new DataLast(wDataSource)
  val genSink = new DataLast(wDataSink)

  val source = IO(elastic.Source(genSource))
  val sink = IO(elastic.Sink(genSink))

  private val steerRight = Module(new SteerRight(wDataSource, wDataSink))
  private val offset = RegInit(0.U(steerRight.wOffset.W))
  private val nextOffset = offset + 1.U

  new elastic.Arrival(source, sink) {
    steerRight.dataIn := in.data
    out.data := steerRight.dataOut

    out.last := in.last && (nextOffset === 0.U)
    steerRight.offsetIn := offset

    protected def onArrival: Unit = {
      produce()

      offset := nextOffset

      when(nextOffset === 0.U) {
        consume()
      }
    }
  }
}
