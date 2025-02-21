package chext.elastic.internal

import chisel3._
import chisel3.util._

import chext.elastic.Chooser

private[elastic] trait ChoosingModule extends InputToOutputSelectModule {
  protected val n: Int
  require(n > 0)

  protected val genSelect = UInt(chisel3.util.log2Up(n).W)

  protected def chooser: Chooser

  protected def onBurst: Unit = chooser.updateState

  protected lazy val lastChoice = Reg(genSelect)
  protected lazy val choice = Mux(sourceBurst, lastChoice, chooser.choice)

  protected def implementChoiceLogic() = {
    lastChoice := choice
  }
}
