package chext.util

import chisel3._
import chisel3.experimental.requireIsChiselType

/** @todo
  *   This class creates a "Vec" of a custom naming scheme. It is meant as a
  *   simple adapter, not to be used in general.
  */
class VecCustomNamed[T <: Data](
    gen: T,
    n: Int,
    nameFn: (Int) => String = (x: Int) => x.toString()
) extends Record
    with IndexedSeq[T] {
  import scala.collection.immutable.SeqMap
  import chisel3.reflect.DataMirror
  import chisel3.experimental.requireIsChiselType

  requireIsChiselType(gen)

  val elements: SeqMap[String, Data] = SeqMap.from(
    Array
      .tabulate(n) {
        case (index) => {
          nameFn(index) -> DataMirror.internal.chiselTypeClone(gen)
        }
      }
      .reverse
  )

  override def apply(index: Int): T = elements(nameFn(index)).asInstanceOf[T]

  override def length: Int = n

  override def className: String = "VecCustomNamed"

  Vec(1, UInt())
}

object VecCustomNamed {
  def apply[T <: Data](
      n: Int,
      gen: T,
      nameFn: (Int) => String = (x: Int) => x.toString()
  ): VecCustomNamed[T] = {
    requireIsChiselType(gen)
    new VecCustomNamed(gen, n, nameFn)
  }

  def zeroExtended[T <: Data](
      n: Int,
      gen: T,
      numDigits: Int = 0
  ): VecCustomNamed[T] = {
    val x = if (numDigits > 0) numDigits else (n - 1).toString().length()
    return apply(n, gen, (index) => String.format(f"%%0${x}d", index))
  }
}
