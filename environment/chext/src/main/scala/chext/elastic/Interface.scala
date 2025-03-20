package chext.elastic

import chisel3._
import chisel3.util._

object Source {
  def apply[T <: Data](x: DecoupledIO[T]): DecoupledIO[T] = Flipped(x)
  def apply[T <: Data](x: IrrevocableIO[T]): IrrevocableIO[T] = Flipped(x)

  def apply[T <: Data](x: T): IrrevocableIO[T] = apply(Irrevocable(x))

  def decoupled[T <: Data](x: T): DecoupledIO[T] = apply(Decoupled(x))
  def irrevocable[T <: Data](x: T): IrrevocableIO[T] = apply(Irrevocable(x))
}

object Sink {
  def apply[T <: Data](x: DecoupledIO[T]): DecoupledIO[T] = x
  def apply[T <: Data](x: IrrevocableIO[T]): IrrevocableIO[T] = x

  def apply[T <: Data](x: T): IrrevocableIO[T] = apply(Irrevocable(x))

  def decoupled[T <: Data](x: T): DecoupledIO[T] = apply(Decoupled(x))
  def irrevocable[T <: Data](x: T): IrrevocableIO[T] = apply(Irrevocable(x))
}
