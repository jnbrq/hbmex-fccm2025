package chext.test

import org.scalatest.Assertions

object Expect {
  def equals[T](a: T, b: T, msg: String = "") = {
    assert(a == b, f"${a} != ${b}. Message: ${msg}")
  }
  
  def condition(b: Boolean, msg: String = "") = {
    assert(b, f"Condition failed. Message: ${msg}")
  }
}
