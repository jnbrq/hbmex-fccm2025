package chext.ip.float

import chisel3._
import chisel3.util._

import chext.elastic
import elastic.ConnectOp._

import chext.bundles.Bundle2

/*
class ElasticAdd(genFp: FloatingPoint, val combinational: Boolean = false) extends Module {
  val sourceInA = IO(elastic.Source(genFp))
  val sourceInB = IO(elastic.Source(genFp))
  val sinkOut = IO(elastic.Sink(genFp))

  private val add = Module(new OpAdd(genFp, combinational))

  // HARDCODED: 8, the queue length
  private val wrapper = Module(new elastic.Wrapper(new Bundle2(genFp, genFp), genFp, add.delay, 8))
  require(add.delay < 8)

  private val join0 = new elastic.Join(wrapper.source) {
    protected def onJoin: Unit = {
      out._1 := join(sourceInA)
      out._2 := join(sourceInB)
    }
  }

  wrapper.sink :=> sinkOut

  add.in_a := wrapper.moduleIn._1
  add.in_b := wrapper.moduleIn._2
  wrapper.moduleOut := add.out
}
*/

class ElasticAdd(genFp: FloatingPoint, val combinational: Boolean = false) extends Module {
  val sourceInA = IO(elastic.Source(genFp))
  val sourceInB = IO(elastic.Source(genFp))
  val sinkOut = IO(elastic.Sink(genFp))

  private val add = Module(new OpAdd(genFp, combinational))

  // HARDCODED: 8, the queue length
  private val wrapper = Module(new elastic.Wrapper(new Bundle2(genFp, genFp), genFp, add.delay, 8))
  require(add.delay < 8)

  private val join0 = new elastic.Join(wrapper.source) {
    protected def onJoin: Unit = {
      out._1 := join(sourceInA)
      out._2 := join(sourceInB)
    }
  }

  wrapper.sink :=> sinkOut

  add.in_a := wrapper.moduleIn._1
  add.in_b := wrapper.moduleIn._2
  wrapper.moduleOut := add.out
}

class ElasticMultiply(genFp: FloatingPoint, val combinational: Boolean = false) extends Module {
  val sourceInA = IO(elastic.Source(genFp))
  val sourceInB = IO(elastic.Source(genFp))
  val sinkOut = IO(elastic.Sink(genFp))

  private val multiply = Module(new OpMultiply(genFp, combinational))

  // HARDCODED: 8, the queue length
  private val wrapper = Module(new elastic.Wrapper(new Bundle2(genFp, genFp), genFp, multiply.delay, 8))

  private val join0 = new elastic.Join(wrapper.source) {
    protected def onJoin: Unit = {
      out._1 := join(sourceInA)
      out._2 := join(sourceInB)
    }
  }

  wrapper.sink :=> sinkOut

  multiply.in_a := wrapper.moduleIn._1
  multiply.in_b := wrapper.moduleIn._2
  wrapper.moduleOut := multiply.out
}

object EmitElastic extends App {
  emitVerilog(new ElasticAdd(FloatingPoint.ieee_fp32))
  emitVerilog(new ElasticMultiply(FloatingPoint.ieee_fp32))
}
