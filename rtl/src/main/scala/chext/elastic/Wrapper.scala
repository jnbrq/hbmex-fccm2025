package chext.elastic

import chisel3._
import chisel3.util._
import chisel3.experimental.AffectsChiselPrefix

import chext.elastic
import elastic.ConnectOp._

class Wrapper[
    InputType <: Data,
    OutputType <: Data,
    ModuleType <: Module
](
    genInput: InputType,
    genOutput: OutputType,
    val moduleDelay: Int,
    val queueLength: Int = 2
) extends Module {
  require(moduleDelay >= 0)
  require(queueLength >= 1)

  val source = IO(elastic.Source(genInput))
  val sink = IO(elastic.Sink(genOutput))

  val moduleIn = IO(Output(genInput))
  val moduleOut = IO(Input(genOutput))

  if (moduleDelay == 0) {
    // this is a combinational module
    moduleIn := source.bits
    sink.bits := moduleOut

    source.ready := sink.ready
    sink.valid := source.valid

  } else {
    val ctr = Module(new chext.util.Counter(queueLength + 1))
    ctr.noInc()
    ctr.noDec()

    val qOutput = Module(new Queue(genOutput, queueLength))

    val outputEnq = qOutput.io.enq
    val outputDeq = qOutput.io.deq

    outputEnq.noenq()
    outputDeq.nodeq()

    source.nodeq()
    sink.noenq()

    moduleIn := source.bits
    outputEnq.bits := moduleOut

    source.ready := ctr.notFull && source.valid

    when(source.fire) {
      ctr.inc()
    }

    outputEnq.valid := ShiftRegister(source.fire, moduleDelay)
    outputDeq :=> sink

    when(outputDeq.fire) {
      ctr.dec()
    }

  }
}
