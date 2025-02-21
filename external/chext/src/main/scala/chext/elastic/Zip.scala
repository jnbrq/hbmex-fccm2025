package chext.elastic

import chisel3._
import chisel3.util._
import chext.bundles._
import scala.collection.mutable.ListBuffer

private object Wrap {
  def decoupled[T <: Data](t: T): DecoupledIO[T] = {
    val result = Wire(Decoupled(chiselTypeOf(t)))
    result.bits := t
    result
  }

  def irrevocable[T <: Data](t: T): IrrevocableIO[T] = {
    val result = Wire(Irrevocable(chiselTypeOf(t)))
    result.bits := t
    result
  }
}

object Zip {
  def apply[T1 <: Data](rv1: ReadyValidIO[T1]) = {
    val rv = Wrap.decoupled(WireBundleN(rv1.bits))
    JoinUtils.join(Seq(rv1), rv)
    rv
  }
  def irrevocable[T1 <: Data](rv1: ReadyValidIO[T1]) = {
    val rv = Wrap.irrevocable(WireBundleN(rv1.bits))
    JoinUtils.join(Seq(rv1), rv)
    rv
  }
  def apply[T1 <: Data, T2 <: Data](
      rv1: ReadyValidIO[T1],
      rv2: ReadyValidIO[T2]
  ) = {
    val rv = Wrap.decoupled(WireBundleN(rv1.bits, rv2.bits))
    JoinUtils.join(Seq(rv1, rv2), rv)
    rv
  }
  def irrevocable[T1 <: Data, T2 <: Data](
      rv1: ReadyValidIO[T1],
      rv2: ReadyValidIO[T2]
  ) = {
    val rv = Wrap.irrevocable(WireBundleN(rv1.bits, rv2.bits))
    JoinUtils.join(Seq(rv1, rv2), rv)
    rv
  }
  def apply[T1 <: Data, T2 <: Data, T3 <: Data](
      rv1: ReadyValidIO[T1],
      rv2: ReadyValidIO[T2],
      rv3: ReadyValidIO[T3]
  ) = {
    val rv = Wrap.decoupled(WireBundleN(rv1.bits, rv2.bits, rv3.bits))
    JoinUtils.join(Seq(rv1, rv2, rv3), rv)
    rv
  }
  def irrevocable[T1 <: Data, T2 <: Data, T3 <: Data](
      rv1: ReadyValidIO[T1],
      rv2: ReadyValidIO[T2],
      rv3: ReadyValidIO[T3]
  ) = {
    val rv = Wrap.irrevocable(WireBundleN(rv1.bits, rv2.bits, rv3.bits))
    JoinUtils.join(Seq(rv1, rv2, rv3), rv)
    rv
  }
  def apply[T1 <: Data, T2 <: Data, T3 <: Data, T4 <: Data](
      rv1: ReadyValidIO[T1],
      rv2: ReadyValidIO[T2],
      rv3: ReadyValidIO[T3],
      rv4: ReadyValidIO[T4]
  ) = {
    val rv = Wrap.decoupled(WireBundleN(rv1.bits, rv2.bits, rv3.bits, rv4.bits))
    JoinUtils.join(Seq(rv1, rv2, rv3, rv4), rv)
    rv
  }
  def irrevocable[T1 <: Data, T2 <: Data, T3 <: Data, T4 <: Data](
      rv1: ReadyValidIO[T1],
      rv2: ReadyValidIO[T2],
      rv3: ReadyValidIO[T3],
      rv4: ReadyValidIO[T4]
  ) = {
    val rv =
      Wrap.irrevocable(WireBundleN(rv1.bits, rv2.bits, rv3.bits, rv4.bits))
    JoinUtils.join(Seq(rv1, rv2, rv3, rv4), rv)
    rv
  }
  def apply[T1 <: Data, T2 <: Data, T3 <: Data, T4 <: Data, T5 <: Data](
      rv1: ReadyValidIO[T1],
      rv2: ReadyValidIO[T2],
      rv3: ReadyValidIO[T3],
      rv4: ReadyValidIO[T4],
      rv5: ReadyValidIO[T5]
  ) = {
    val rv = Wrap.decoupled(
      WireBundleN(rv1.bits, rv2.bits, rv3.bits, rv4.bits, rv5.bits)
    )
    JoinUtils.join(Seq(rv1, rv2, rv3, rv4, rv5), rv)
    rv
  }
  def irrevocable[T1 <: Data, T2 <: Data, T3 <: Data, T4 <: Data, T5 <: Data](
      rv1: ReadyValidIO[T1],
      rv2: ReadyValidIO[T2],
      rv3: ReadyValidIO[T3],
      rv4: ReadyValidIO[T4],
      rv5: ReadyValidIO[T5]
  ) = {
    val rv = Wrap.irrevocable(
      WireBundleN(rv1.bits, rv2.bits, rv3.bits, rv4.bits, rv5.bits)
    )
    JoinUtils.join(Seq(rv1, rv2, rv3, rv4, rv5), rv)
    rv
  }
  def apply[
      T1 <: Data,
      T2 <: Data,
      T3 <: Data,
      T4 <: Data,
      T5 <: Data,
      T6 <: Data
  ](
      rv1: ReadyValidIO[T1],
      rv2: ReadyValidIO[T2],
      rv3: ReadyValidIO[T3],
      rv4: ReadyValidIO[T4],
      rv5: ReadyValidIO[T5],
      rv6: ReadyValidIO[T6]
  ) = {
    val rv = Wrap.decoupled(
      WireBundleN(rv1.bits, rv2.bits, rv3.bits, rv4.bits, rv5.bits, rv6.bits)
    )
    JoinUtils.join(Seq(rv1, rv2, rv3, rv4, rv5, rv6), rv)
    rv
  }
  def irrevocable[
      T1 <: Data,
      T2 <: Data,
      T3 <: Data,
      T4 <: Data,
      T5 <: Data,
      T6 <: Data
  ](
      rv1: ReadyValidIO[T1],
      rv2: ReadyValidIO[T2],
      rv3: ReadyValidIO[T3],
      rv4: ReadyValidIO[T4],
      rv5: ReadyValidIO[T5],
      rv6: ReadyValidIO[T6]
  ) = {
    val rv = Wrap.irrevocable(
      WireBundleN(rv1.bits, rv2.bits, rv3.bits, rv4.bits, rv5.bits, rv6.bits)
    )
    JoinUtils.join(Seq(rv1, rv2, rv3, rv4, rv5, rv6), rv)
    rv
  }
  def apply[
      T1 <: Data,
      T2 <: Data,
      T3 <: Data,
      T4 <: Data,
      T5 <: Data,
      T6 <: Data,
      T7 <: Data
  ](
      rv1: ReadyValidIO[T1],
      rv2: ReadyValidIO[T2],
      rv3: ReadyValidIO[T3],
      rv4: ReadyValidIO[T4],
      rv5: ReadyValidIO[T5],
      rv6: ReadyValidIO[T6],
      rv7: ReadyValidIO[T7]
  ) = {
    val rv = Wrap.decoupled(
      WireBundleN(
        rv1.bits,
        rv2.bits,
        rv3.bits,
        rv4.bits,
        rv5.bits,
        rv6.bits,
        rv7.bits
      )
    )
    JoinUtils.join(Seq(rv1, rv2, rv3, rv4, rv5, rv6, rv7), rv)
    rv
  }
  def irrevocable[
      T1 <: Data,
      T2 <: Data,
      T3 <: Data,
      T4 <: Data,
      T5 <: Data,
      T6 <: Data,
      T7 <: Data
  ](
      rv1: ReadyValidIO[T1],
      rv2: ReadyValidIO[T2],
      rv3: ReadyValidIO[T3],
      rv4: ReadyValidIO[T4],
      rv5: ReadyValidIO[T5],
      rv6: ReadyValidIO[T6],
      rv7: ReadyValidIO[T7]
  ) = {
    val rv = Wrap.irrevocable(
      WireBundleN(
        rv1.bits,
        rv2.bits,
        rv3.bits,
        rv4.bits,
        rv5.bits,
        rv6.bits,
        rv7.bits
      )
    )
    JoinUtils.join(Seq(rv1, rv2, rv3, rv4, rv5, rv6, rv7), rv)
    rv
  }
  def apply[
      T1 <: Data,
      T2 <: Data,
      T3 <: Data,
      T4 <: Data,
      T5 <: Data,
      T6 <: Data,
      T7 <: Data,
      T8 <: Data
  ](
      rv1: ReadyValidIO[T1],
      rv2: ReadyValidIO[T2],
      rv3: ReadyValidIO[T3],
      rv4: ReadyValidIO[T4],
      rv5: ReadyValidIO[T5],
      rv6: ReadyValidIO[T6],
      rv7: ReadyValidIO[T7],
      rv8: ReadyValidIO[T8]
  ) = {
    val rv = Wrap.decoupled(
      WireBundleN(
        rv1.bits,
        rv2.bits,
        rv3.bits,
        rv4.bits,
        rv5.bits,
        rv6.bits,
        rv7.bits,
        rv8.bits
      )
    )
    JoinUtils.join(Seq(rv1, rv2, rv3, rv4, rv5, rv6, rv7, rv8), rv)
    rv
  }
  def irrevocable[
      T1 <: Data,
      T2 <: Data,
      T3 <: Data,
      T4 <: Data,
      T5 <: Data,
      T6 <: Data,
      T7 <: Data,
      T8 <: Data
  ](
      rv1: ReadyValidIO[T1],
      rv2: ReadyValidIO[T2],
      rv3: ReadyValidIO[T3],
      rv4: ReadyValidIO[T4],
      rv5: ReadyValidIO[T5],
      rv6: ReadyValidIO[T6],
      rv7: ReadyValidIO[T7],
      rv8: ReadyValidIO[T8]
  ) = {
    val rv = Wrap.irrevocable(
      WireBundleN(
        rv1.bits,
        rv2.bits,
        rv3.bits,
        rv4.bits,
        rv5.bits,
        rv6.bits,
        rv7.bits,
        rv8.bits
      )
    )
    JoinUtils.join(Seq(rv1, rv2, rv3, rv4, rv5, rv6, rv7, rv8), rv)
    rv
  }
}
