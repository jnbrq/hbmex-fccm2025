package chext.elastic

import chisel3._
import util.log2Ceil

class Counter(val maxValueExclusive: Int, val start: Int = 0) extends Module {
  require(start < maxValueExclusive)

  val width = log2Ceil(maxValueExclusive)

  val sink = IO(Sink(UInt(width.W)))
  private val counter = RegInit(start.U(width.W))

  sink.enq(counter)

  when(sink.fire) {
    when(counter === (maxValueExclusive - 1).U) {
      counter := 0.U
    }.otherwise {
      counter := counter + 1.U
    }
  }
}

object Counter {
  def apply(maxValueExclusive: Int = 0, start: Int = 0) = {
    val elasticCounter = Module(new Counter(maxValueExclusive, start))
    elasticCounter.sink
  }
}
