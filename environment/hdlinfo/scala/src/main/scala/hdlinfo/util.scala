package hdlinfo.util

/** Returns whether a Scala integer is a power of two.
  *
  * @example {{{
  * isPow2(1)  // returns true
  * isPow2(2)  // returns true
  * isPow2(3)  // returns false
  * isPow2(4)  // returns true
  * }}}
  */
object isPow2 {
  def apply(in: BigInt): Boolean = in > 0 && ((in & (in - 1)) == 0)
  def apply(in: Int):    Boolean = apply(BigInt(in))
}
