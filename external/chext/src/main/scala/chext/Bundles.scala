package chext.bundles

import chisel3._

class Bundle1[T1 <: Data](gen1: T1) extends Bundle { val _1 = gen1.cloneType }
class Bundle2[T1 <: Data, T2 <: Data](gen1: T1, gen2: T2) extends Bundle {
  val _1 = gen1.cloneType
  val _2 = gen2.cloneType
}
class Bundle3[T1 <: Data, T2 <: Data, T3 <: Data](gen1: T1, gen2: T2, gen3: T3)
    extends Bundle {
  val _1 = gen1.cloneType
  val _2 = gen2.cloneType
  val _3 = gen3.cloneType
}
class Bundle4[T1 <: Data, T2 <: Data, T3 <: Data, T4 <: Data](
    gen1: T1,
    gen2: T2,
    gen3: T3,
    gen4: T4
) extends Bundle {
  val _1 = gen1.cloneType
  val _2 = gen2.cloneType
  val _3 = gen3.cloneType
  val _4 = gen4.cloneType
}
class Bundle5[T1 <: Data, T2 <: Data, T3 <: Data, T4 <: Data, T5 <: Data](
    gen1: T1,
    gen2: T2,
    gen3: T3,
    gen4: T4,
    gen5: T5
) extends Bundle {
  val _1 = gen1.cloneType
  val _2 = gen2.cloneType
  val _3 = gen3.cloneType
  val _4 = gen4.cloneType
  val _5 = gen5.cloneType
}
class Bundle6[
    T1 <: Data,
    T2 <: Data,
    T3 <: Data,
    T4 <: Data,
    T5 <: Data,
    T6 <: Data
](gen1: T1, gen2: T2, gen3: T3, gen4: T4, gen5: T5, gen6: T6)
    extends Bundle {
  val _1 = gen1.cloneType
  val _2 = gen2.cloneType
  val _3 = gen3.cloneType
  val _4 = gen4.cloneType
  val _5 = gen5.cloneType
  val _6 = gen6.cloneType
}
class Bundle7[
    T1 <: Data,
    T2 <: Data,
    T3 <: Data,
    T4 <: Data,
    T5 <: Data,
    T6 <: Data,
    T7 <: Data
](gen1: T1, gen2: T2, gen3: T3, gen4: T4, gen5: T5, gen6: T6, gen7: T7)
    extends Bundle {
  val _1 = gen1.cloneType
  val _2 = gen2.cloneType
  val _3 = gen3.cloneType
  val _4 = gen4.cloneType
  val _5 = gen5.cloneType
  val _6 = gen6.cloneType
  val _7 = gen7.cloneType
}
class Bundle8[
    T1 <: Data,
    T2 <: Data,
    T3 <: Data,
    T4 <: Data,
    T5 <: Data,
    T6 <: Data,
    T7 <: Data,
    T8 <: Data
](
    gen1: T1,
    gen2: T2,
    gen3: T3,
    gen4: T4,
    gen5: T5,
    gen6: T6,
    gen7: T7,
    gen8: T8
) extends Bundle {
  val _1 = gen1.cloneType
  val _2 = gen2.cloneType
  val _3 = gen3.cloneType
  val _4 = gen4.cloneType
  val _5 = gen5.cloneType
  val _6 = gen6.cloneType
  val _7 = gen7.cloneType
  val _8 = gen8.cloneType
}
object WireBundleN {
  def apply[T1 <: Data](t1: T1): Bundle1[T1] = {
    val result = Wire(new Bundle1(chiselTypeOf(t1)))
    result._1 <> t1
    result
  }
  def apply[T1 <: Data, T2 <: Data](t1: T1, t2: T2): Bundle2[T1, T2] = {
    val result = Wire(new Bundle2(chiselTypeOf(t1), chiselTypeOf(t2)))
    result._1 := t1
    result._2 := t2
    result
  }
  def apply[T1 <: Data, T2 <: Data, T3 <: Data](
      t1: T1,
      t2: T2,
      t3: T3
  ): Bundle3[T1, T2, T3] = {
    val result = Wire(
      new Bundle3(chiselTypeOf(t1), chiselTypeOf(t2), chiselTypeOf(t3))
    )
    result._1 <> t1
    result._2 <> t2
    result._3 <> t3
    result
  }
  def apply[T1 <: Data, T2 <: Data, T3 <: Data, T4 <: Data](
      t1: T1,
      t2: T2,
      t3: T3,
      t4: T4
  ): Bundle4[T1, T2, T3, T4] = {
    val result = Wire(
      new Bundle4(
        chiselTypeOf(t1),
        chiselTypeOf(t2),
        chiselTypeOf(t3),
        chiselTypeOf(t4)
      )
    )
    result._1 <> t1
    result._2 <> t2
    result._3 <> t3
    result._4 <> t4
    result
  }
  def apply[T1 <: Data, T2 <: Data, T3 <: Data, T4 <: Data, T5 <: Data](
      t1: T1,
      t2: T2,
      t3: T3,
      t4: T4,
      t5: T5
  ): Bundle5[T1, T2, T3, T4, T5] = {
    val result = Wire(
      new Bundle5(
        chiselTypeOf(t1),
        chiselTypeOf(t2),
        chiselTypeOf(t3),
        chiselTypeOf(t4),
        chiselTypeOf(t5)
      )
    )
    result._1 <> t1
    result._2 <> t2
    result._3 <> t3
    result._4 <> t4
    result._5 <> t5
    result
  }
  def apply[
      T1 <: Data,
      T2 <: Data,
      T3 <: Data,
      T4 <: Data,
      T5 <: Data,
      T6 <: Data
  ](
      t1: T1,
      t2: T2,
      t3: T3,
      t4: T4,
      t5: T5,
      t6: T6
  ): Bundle6[T1, T2, T3, T4, T5, T6] = {
    val result = Wire(
      new Bundle6(
        chiselTypeOf(t1),
        chiselTypeOf(t2),
        chiselTypeOf(t3),
        chiselTypeOf(t4),
        chiselTypeOf(t5),
        chiselTypeOf(t6)
      )
    )
    result._1 <> t1
    result._2 <> t2
    result._3 <> t3
    result._4 <> t4
    result._5 <> t5
    result._6 <> t6
    result
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
      t1: T1,
      t2: T2,
      t3: T3,
      t4: T4,
      t5: T5,
      t6: T6,
      t7: T7
  ): Bundle7[T1, T2, T3, T4, T5, T6, T7] = {
    val result = Wire(
      new Bundle7(
        chiselTypeOf(t1),
        chiselTypeOf(t2),
        chiselTypeOf(t3),
        chiselTypeOf(t4),
        chiselTypeOf(t5),
        chiselTypeOf(t6),
        chiselTypeOf(t7)
      )
    )
    result._1 <> t1
    result._2 <> t2
    result._3 <> t3
    result._4 <> t4
    result._5 <> t5
    result._6 <> t6
    result._7 <> t7
    result
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
  ](t1: T1, t2: T2, t3: T3, t4: T4, t5: T5, t6: T6, t7: T7, t8: T8)
      : Bundle8[T1, T2, T3, T4, T5, T6, T7, T8] = {
    val result = Wire(
      new Bundle8(
        chiselTypeOf(t1),
        chiselTypeOf(t2),
        chiselTypeOf(t3),
        chiselTypeOf(t4),
        chiselTypeOf(t5),
        chiselTypeOf(t6),
        chiselTypeOf(t7),
        chiselTypeOf(t8)
      )
    )
    result._1 <> t1
    result._2 <> t2
    result._3 <> t3
    result._4 <> t4
    result._5 <> t5
    result._6 <> t6
    result._7 <> t7
    result._8 <> t8
    result
  }
}

object BundleN {
  def apply[T1 <: Data](gen1: T1): Bundle1[T1] =
    new Bundle1(gen1)
  def apply[T1 <: Data, T2 <: Data](gen1: T1, gen2: T2): Bundle2[T1, T2] =
    new Bundle2(gen1, gen2)
  def apply[T1 <: Data, T2 <: Data, T3 <: Data](
      gen1: T1,
      gen2: T2,
      gen3: T3
  ): Bundle3[T1, T2, T3] =
    new Bundle3(gen1, gen2, gen3)
  def apply[T1 <: Data, T2 <: Data, T3 <: Data, T4 <: Data](
      gen1: T1,
      gen2: T2,
      gen3: T3,
      gen4: T4
  ): Bundle4[T1, T2, T3, T4] =
    new Bundle4(gen1, gen2, gen3, gen4)
  def apply[T1 <: Data, T2 <: Data, T3 <: Data, T4 <: Data, T5 <: Data](
      gen1: T1,
      gen2: T2,
      gen3: T3,
      gen4: T4,
      gen5: T5
  ): Bundle5[T1, T2, T3, T4, T5] =
    new Bundle5(gen1, gen2, gen3, gen4, gen5)
  def apply[
      T1 <: Data,
      T2 <: Data,
      T3 <: Data,
      T4 <: Data,
      T5 <: Data,
      T6 <: Data
  ](
      gen1: T1,
      gen2: T2,
      gen3: T3,
      gen4: T4,
      gen5: T5,
      gen6: T6
  ): Bundle6[T1, T2, T3, T4, T5, T6] =
    new Bundle6(gen1, gen2, gen3, gen4, gen5, gen6)
  def apply[
      T1 <: Data,
      T2 <: Data,
      T3 <: Data,
      T4 <: Data,
      T5 <: Data,
      T6 <: Data,
      T7 <: Data
  ](
      gen1: T1,
      gen2: T2,
      gen3: T3,
      gen4: T4,
      gen5: T5,
      gen6: T6,
      gen7: T7
  ): Bundle7[T1, T2, T3, T4, T5, T6, T7] =
    new Bundle7(gen1, gen2, gen3, gen4, gen5, gen6, gen7)
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
      gen1: T1,
      gen2: T2,
      gen3: T3,
      gen4: T4,
      gen5: T5,
      gen6: T6,
      gen7: T7,
      gen8: T8
  ): Bundle8[T1, T2, T3, T4, T5, T6, T7, T8] =
    new Bundle8(gen1, gen2, gen3, gen4, gen5, gen6, gen7, gen8)
}
