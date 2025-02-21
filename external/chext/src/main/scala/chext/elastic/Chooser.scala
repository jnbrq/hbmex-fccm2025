package chext.elastic

import chisel3._
import chisel3.util._
import chisel3.experimental.AffectsChiselPrefix

abstract class Chooser(val v: Vec[Bool]) extends AffectsChiselPrefix {
  protected val wChoice = chisel3.util.log2Up(v.length)
  protected val genChoice = UInt(wChoice.W)
  protected val zeroChoice = 0.U(wChoice.W)

  /** The chooser makes a choice based on `v`s and its current internal state.
    *
    * @return
    */
  def choice: UInt

  /** Logic active when a selection is to be made.
    */
  def updateState: Unit
}

class RRChooser(v: Vec[Bool]) extends Chooser(v) {
  private val lastChoice = RegInit(zeroChoice)
  private val choiceMax = (-1).S(wChoice.W).asUInt

  override def choice: UInt = {
    Mux(v(rrChoice), rrChoice, priorityChoice)
  }
  override def updateState: Unit = (lastChoice := choice)

  private val rrChoice =
    Mux(
      lastChoice === choiceMax,
      zeroChoice,
      PriorityEncoder(v.zipWithIndex.map { case (x, i) =>
        i.U > lastChoice && x
      })
    )
  private val priorityChoice = PriorityEncoder(v)

}

class PriorityChooser(v: Vec[Bool]) extends Chooser(v) {
  def choice: UInt = {
    PriorityEncoder(v)
  }

  def updateState: Unit = { /* stateless */ }
}

object Chooser {
  type ChooserFn = (Vec[Bool]) => Chooser

  def rr(v: Vec[Bool]) = new RRChooser(v)
  def priority(v: Vec[Bool]) = new PriorityChooser(v)
}
