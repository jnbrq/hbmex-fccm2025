package chext.elastic

import chisel3._
import chisel3.util._
import chisel3.experimental._
import scala.collection.mutable.ListBuffer

abstract class Fork[T <: Data](source: ReadyValidIO[T]) extends AffectsChiselPrefix {
  private val sinkList = ListBuffer.empty[ReadyValidIO[Data]]
  protected val in = source.bits

  object fork {
    def apply[TT <: Data](tt: TT = in): DecoupledIO[TT] = {
      val result = Wire(new DecoupledIO(chiselTypeOf(tt)))
      result.bits := tt
      sinkList.addOne(result)
      result
    }

    def irrevocable[TT <: Data](tt: TT = in): IrrevocableIO[TT] = {
      val result = Wire(new IrrevocableIO(chiselTypeOf(tt)))
      result.bits := tt
      sinkList.addOne(result)
      result
    }
  }

  protected def onFork: Unit

  onFork
  eagerFork(source, sinkList.toSeq)
}

object Clone {
  def apply[T <: Data](
      source: ReadyValidIO[T],
      n: Int
  ): Seq[DecoupledIO[T]] = {
    val sinks = Seq.fill(n) {
      val r = Wire(new DecoupledIO(chiselTypeOf(source.bits)))
      r.bits := source.bits
      r
    }
    eagerFork(source, sinks)
    sinks
  }

  def irrevocable[T <: Data](
      source: ReadyValidIO[T],
      n: Int
  ): Seq[IrrevocableIO[T]] = {
    val sinks = Seq.fill(n) {
      val r = Wire(new IrrevocableIO(chiselTypeOf(source.bits)))
      r.bits := source.bits
      r
    }
    eagerFork(source, sinks)
    sinks
  }
}

object eagerFork {

  /** Implements an eager fork.
    *
    * @param f
    * @return
    */
  def apply[T <: Data](
      source: ReadyValidIO[T],
      sinks: Seq[ReadyValidIO[Data]]
  ): Unit = {
    prefix("eagerFork") {
      // registers to remember if transmission already took place
      val regs = RegInit(VecInit(Seq.fill(sinks.length) { false.B }))

      sinks.zip(regs).foreach {
        case (sink, reg) => {
          sink.valid := source.valid && !reg
        }
      }

      source.ready := VecInit(sinks.zip(regs).map {
        case (sink, reg) => {
          sink.ready || reg
        }
      }).reduceTree(_ && _)

      sinks.zip(regs).foreach {
        case (sink, reg) => {
          // the next value for the register
          reg := (sink.ready || reg) && source.valid && !source.ready
        }
      }
    }
  }
}
