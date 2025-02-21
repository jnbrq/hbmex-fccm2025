package chext.elastic.internal

import chisel3._
import chisel3.util._

/**
  * Implements the control logic for a module that cosnumes input(s) and produces
  * output(s) and a select stream.
  * 
  * It supports bursts.
  */
trait InputToOutputSelectModule {
  protected val sourceBurst = RegInit(false.B)

  protected def sourceValid: Bool
  protected def sourceLast: Bool
  protected def sourceReady: Bool

  protected def selectValid: Bool
  protected def selectReady: Bool

  protected def sinkValid: Bool
  protected def sinkReady: Bool

  /** Initializes the data path and connects the control signals.
    */
  protected def implementDataPlane(): Unit

  /** Logic executed when a Burst starts.
    */
  protected def onBurst: Unit

  /** Initializes the control signals
    */
  protected def implementControlPlane(): Unit = {
    val sinkSent = RegInit(false.B)
    val selectSent = RegInit(false.B)

    def isSentLogic(sinkReady: Bool, sinkSent: Bool) = {
      sinkSent := (sinkReady || sinkSent) && sourceValid && !sourceReady
    }

    isSentLogic(sinkReady, sinkSent)
    isSentLogic(selectReady, selectSent)

    selectValid := sourceValid && !selectSent && sourceLast
    sinkValid := sourceValid && !sinkSent

    sourceReady := (sinkSent || sinkReady) &&
      (!sourceLast || sourceLast && (selectSent || selectReady))

    when(sourceValid && sourceReady) {
      when(sourceLast) {
        sourceBurst := false.B
      }.otherwise {
        sourceBurst := true.B
      }

      when(!sourceBurst) {
        onBurst
      }
    }
  }
}
