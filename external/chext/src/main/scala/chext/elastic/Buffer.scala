package chext.elastic

import chext.elastic

import chisel3._
import chisel3.util._
import chisel3.experimental._

import elastic.ConnectOp._

object UnsafeCasts {
  implicit class unsafe_casts[T <: Data](rv: ReadyValidIO[T]) {
    private def implInput(result: ReadyValidIO[T]) = {
      result.bits := rv.bits
      result.valid := rv.valid
      rv.ready := result.ready
    }

    private def implOutput(result: ReadyValidIO[T]) = {
      rv.bits := result.bits
      rv.valid := result.valid
      result.ready := rv.ready
    }

    def asSourceDecoupled = {
      val result = Wire(new DecoupledIO(rv.bits.cloneType))
      implInput(result)
      result
    }

    def asSinkDecoupled = {
      val result = Wire(new DecoupledIO(rv.bits.cloneType))
      implOutput(result)
      result
    }

    def asSourceIrrevocable = {
      val result = Wire(new IrrevocableIO(rv.bits.cloneType))
      implInput(result)
      result
    }

    def asSinkIrrevocable = {
      val result = Wire(new IrrevocableIO(rv.bits.cloneType))
      implOutput(result)
      result
    }
  }
}

object SourceBuffer {
  def apply[T <: Data](source: DecoupledIO[T]): DecoupledIO[T] = {
    decoupled(source, 2)
  }

  def apply[T <: Data](source: DecoupledIO[T], n: Int): DecoupledIO[T] = {
    decoupled(source, n)
  }

  def apply[T <: Data](source: DecoupledIO[T], n: Int, flow: Boolean): DecoupledIO[T] = {
    decoupled(source, n, flow)
  }

  def apply[T <: Data](
      source: DecoupledIO[T],
      n: Int,
      flow: Boolean,
      pipe: Boolean
  ): DecoupledIO[T] = {
    decoupled(source, n, flow, pipe)
  }

  def apply[T <: Data](source: IrrevocableIO[T]): IrrevocableIO[T] = {
    irrevocable(source, 2)
  }

  def apply[T <: Data](source: IrrevocableIO[T], n: Int): IrrevocableIO[T] = {
    irrevocable(source, n)
  }

  def apply[T <: Data](source: IrrevocableIO[T], n: Int, flow: Boolean): IrrevocableIO[T] = {
    irrevocable(source, n, flow)
  }

  def apply[T <: Data](
      source: IrrevocableIO[T],
      n: Int,
      flow: Boolean,
      pipe: Boolean
  ): IrrevocableIO[T] = {
    irrevocable(source, n, flow, pipe)
  }

  def decoupled[T <: Data](
      source: ReadyValidIO[T],
      n: Int = 2,
      flow: Boolean = false,
      pipe: Boolean = false
  ): DecoupledIO[T] = {
    import UnsafeCasts._
    if (n == 0)
      source.asSourceDecoupled
    else {
      val sourceBuffer = Module(
        new Queue(chiselTypeOf(source.bits), n, flow = flow, pipe = pipe)
      )

      source :=> sourceBuffer.io.enq
      sourceBuffer.io.deq
    }
  }

  def irrevocable[T <: Data](
      source: ReadyValidIO[T],
      n: Int = 2,
      flow: Boolean = false,
      pipe: Boolean = false
  ): IrrevocableIO[T] = {
    import UnsafeCasts._
    if (n == 0)
      source.asSourceIrrevocable
    else {
      val sourceBuffer = Module(
        new Queue(chiselTypeOf(source.bits), n, flow, pipe)
      )
      val result = Wire(new IrrevocableIO(chiselTypeOf(source.bits)))

      source :=> sourceBuffer.io.enq
      sourceBuffer.io.deq :=> result

      result
    }
  }
}

object SinkBuffer {
  def apply[T <: Data](sink: DecoupledIO[T]): DecoupledIO[T] = {
    decoupled(sink, 2)
  }

  def apply[T <: Data](sink: DecoupledIO[T], n: Int): DecoupledIO[T] = {
    decoupled(sink, n)
  }

  def apply[T <: Data](sink: DecoupledIO[T], n: Int, flow: Boolean): DecoupledIO[T] = {
    decoupled(sink, n, flow)
  }

  def apply[T <: Data](
      sink: DecoupledIO[T],
      n: Int,
      flow: Boolean,
      pipe: Boolean
  ): DecoupledIO[T] = {
    decoupled(sink, n, flow, pipe)
  }

  def apply[T <: Data](sink: IrrevocableIO[T]): IrrevocableIO[T] = {
    irrevocable(sink, 2)
  }

  def apply[T <: Data](sink: IrrevocableIO[T], n: Int): IrrevocableIO[T] = {
    irrevocable(sink, n)
  }

  def apply[T <: Data](sink: IrrevocableIO[T], n: Int, flow: Boolean): IrrevocableIO[T] = {
    irrevocable(sink, n, flow)
  }

  def apply[T <: Data](
      sink: IrrevocableIO[T],
      n: Int,
      flow: Boolean,
      pipe: Boolean
  ): IrrevocableIO[T] = {
    irrevocable(sink, n, flow, pipe)
  }

  def decoupled[T <: Data](
      sink: ReadyValidIO[T],
      n: Int = 2,
      flow: Boolean = false,
      pipe: Boolean = false
  ): DecoupledIO[T] = {
    import UnsafeCasts._
    if (n == 0)
      sink.asSinkDecoupled
    else {
      val sinkBuffer = Module(
        new Queue(chiselTypeOf(sink.bits), n, flow = flow, pipe = pipe)
      )

      sinkBuffer.io.deq :=> sink
      sinkBuffer.io.enq
    }
  }

  def irrevocable[T <: Data](
      sink: ReadyValidIO[T],
      n: Int = 2,
      flow: Boolean = false,
      pipe: Boolean = false
  ): IrrevocableIO[T] = {
    import UnsafeCasts._
    if (n == 0)
      sink.asSinkIrrevocable
    else {
      val sinkBuffer = Module(
        new Queue(chiselTypeOf(sink.bits), n, flow = flow, pipe = pipe)
      )
      val result = Wire(new IrrevocableIO(chiselTypeOf(sink.bits)))

      sinkBuffer.io.deq :=> sink
      result :=> sinkBuffer.io.enq

      result
    }
  }
}
