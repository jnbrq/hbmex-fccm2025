package hbmex.components.spmv

import chisel3._
import chisel3.util._

import chext.elastic
import elastic.ConnectOp._

import chext.ip.float

import chext.bundles.Bundle2

class BatchMultiply extends Module {
  val genFp = float.FloatingPoint.ieee_fp32

  val sourceInA = IO(elastic.Source(UInt(32.W))) // HARDCODED
  val sourceInB = IO(elastic.Source(UInt(256.W))) // HARDCODED
  val sinkOut = IO(elastic.Sink(UInt(256.W))) // HARDCODED

  private val multiplyN = Seq.tabulate(8) { // HARDCODED
    index => Module(new float.OpMultiply(genFp)).suggestName(f"multiply$index")
  }

  // HARDCODED
  private val wrapper = Module(new elastic.Wrapper(new Bundle2(UInt(32.W), UInt(256.W)), UInt(256.W), multiplyN.head.delay, 4))

  private val join0 = new elastic.Join(wrapper.source) {
    protected def onJoin: Unit = {
      out._1 := join(sourceInA)
      out._2 := join(sourceInB)
    }
  }

  wrapper.sink :=> sinkOut

  multiplyN.foreach {
    case (multiply) => {
      multiply.in_a := wrapper.moduleIn._1.asTypeOf(genFp)
    }
  }

  // HARDCODED
  multiplyN.zip(wrapper.moduleIn._2.asTypeOf(Vec(8, genFp))).foreach {
    case (multiply, fp) => {
      multiply.in_b := fp
    }
  }

  wrapper.moduleOut := VecInit(multiplyN.map { _.out }).asUInt
}

object BatchAdd {
  val genFp = float.FloatingPoint.ieee_fp32

  // HARDCODED
  val genReq = new Bundle2(UInt(256.W), UInt(256.W))

  // HARDCODED
  val genResp = UInt(256.W)
}

class BatchAdd extends Module {
  val req = IO(elastic.Source(BatchAdd.genReq))
  val resp = IO(elastic.Sink(BatchAdd.genResp))

  private val addN = Seq.tabulate(8) { // HARDCODED
    index => Module(new float.OpAdd(BatchAdd.genFp)).suggestName(f"add$index")
  }

  // HARDCODED
  private val wrapper = Module(new elastic.Wrapper(BatchAdd.genReq, BatchAdd.genResp, addN.head.delay, 8))

  req :=> wrapper.source
  wrapper.sink :=> resp

  // HARDCODED
  addN.zip(wrapper.moduleIn._1.asTypeOf(Vec(8, BatchAdd.genFp))).foreach {
    case (add, fp) => {
      add.in_a := fp
    }
  }

  // HARDCODED
  addN.zip(wrapper.moduleIn._2.asTypeOf(Vec(8, BatchAdd.genFp))).foreach {
    case (add, fp) => {
      add.in_b := fp
    }
  }

  wrapper.moduleOut := VecInit(addN.map { _.out }).asUInt
}
