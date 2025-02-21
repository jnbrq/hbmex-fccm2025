package chext.ip.float

import chisel3._
import chisel3.util._

import scala.collection.mutable.ArrayBuffer
import scala.collection.mutable.HashMap

private trait PipelineHelper extends Module {
  case class Signal[T <: Data](signalName: String) {
    def get: T = getSignal(signalName).get.asInstanceOf[T]
  }

  final def newStage(): Unit = {
    currentStageIndex = currentStageIndex + 1
    stages.addOne(HashMap.empty[String, Data])
  }

  final def wrap[T <: Data](t: T, name: String): Signal[T] = {
    registerSignal(t, name)
    new Signal(name)
  }

  /** Current stage that we are in.
    */
  private var currentStageIndex = -1

  /** Stores signals defined in each stage.
    */
  private var stages = ArrayBuffer.empty[HashMap[String, Data]]

  /** Keeps track of the first stage a signal was generated.
    */
  private var signalsToFirstStage = HashMap.empty[String, Int]

  newStage()

  private def getSignal(signalName: String): Option[Data] = {
    signalsToFirstStage.get(signalName).map {
      case (firstStageIndex) => {
        var last: Data = stages(firstStageIndex)(signalName)

        for (stageIndex <- ((firstStageIndex + 1) to currentStageIndex)) {
          last = stages(stageIndex).getOrElseUpdate(
            signalName, {
              val nextReg = Reg(chiselTypeOf(last)).suggestName(f"stage${stageIndex}_${signalName}")
              nextReg := last
              nextReg
            }
          )
        }

        last
      }
    }
  }

  private def registerSignal[T <: Data](t: Data, signalName: String) = {
    if (signalsToFirstStage.get(signalName).nonEmpty)
      throw new Exception(f"A signal called ${signalName} already exists!")

    t.suggestName(f"stage${currentStageIndex}_${signalName}")

    stages(currentStageIndex).addOne(signalName -> t)
    signalsToFirstStage.addOne(signalName -> currentStageIndex)
  }
}

/** As an example for and for testing the pipeline helper.
  */
private class StupidModule extends Module with PipelineHelper {
  val io = IO(new Bundle {
    val in_a = Input(UInt(32.W))
    val in_b = Input(UInt(32.W))
    val in_c = Input(UInt(32.W))
    val in_d = Input(UInt(32.W))
    val out = Output(UInt(32.W))
  })

  private val a = wrap(io.in_a, "a")
  private val b = wrap(io.in_b, "b")
  private val c = wrap(io.in_c, "c")
  private val d = wrap(io.in_d, "d")

  newStage()

  private val ab = wrap(a.get + b.get, "ab")
  private val cd = wrap(c.get + d.get, "cd")

  newStage()

  private val abcd = wrap(ab.get + cd.get, "abcd")

  newStage()

  io.out := abcd.get
}

private object EmitStupidModule extends App {
  emitVerilog(new StupidModule)
}

import hardfloat.{
  RawFloat,
  RoundRawFNToRecFN,
  AddRecFN,
  MulRawFN,
  MulRecFN,
  orReduceBy2,
  orReduceBy4,
  lowMask,
  isSigNaNRawFloat,
  countLeadingZeros,
  rawFloatFromRecFN,
  recFNFromFN,
  fNFromRecFN
}
import hardfloat.consts.{round_min, round_near_even}

private class AddRawFN_Pipelined(expWidth: Int, sigWidth: Int) extends Module with PipelineHelper {
  override val desiredName = f"AddRawFN_Pipelined_${expWidth}_${sigWidth}"

  val io = IO(new Bundle {
    val subOp = Input(Bool())
    val a = Input(new RawFloat(expWidth, sigWidth))
    val b = Input(new RawFloat(expWidth, sigWidth))
    val roundingMode = Input(UInt(3.W))
    val invalidExc = Output(Bool())
    val rawOut = Output(new RawFloat(expWidth, sigWidth + 2))
  })

  private val alignDistWidth = log2Ceil(sigWidth)

  private val subOp = wrap(io.subOp, "subOp")
  private val a = wrap(io.a, "a")
  private val b = wrap(io.b, "b")
  private val roundingMode = wrap(io.roundingMode, "roundingMode")

  private val effSignB = wrap(b.get.sign ^ subOp.get, "effSignB")
  private val eqSigns = wrap(a.get.sign === effSignB.get, "eqSigns")
  private val notEqSigns_signZero = wrap(roundingMode.get === round_min, "notEqSigns_signZero")
  private val sDiffExps = wrap(a.get.sExp - b.get.sExp, "sDiffExps")
  private val modNatAlignDist = wrap(Mux(sDiffExps.get < 0.S, b.get.sExp - a.get.sExp, sDiffExps.get)(alignDistWidth - 1, 0), "modNatAlignDist")
  private val isMaxAlign =
    wrap(
      (sDiffExps.get >> alignDistWidth) =/= 0.S &&
        ((sDiffExps.get >> alignDistWidth) =/= -1.S || sDiffExps.get(alignDistWidth - 1, 0) === 0.U),
      "isMaxAlign"
    )
  private val alignDist = wrap(Mux(isMaxAlign.get, ((BigInt(1) << alignDistWidth) - 1).U, modNatAlignDist.get), "alignDist")
  private val closeSubMags = wrap(!eqSigns.get && !isMaxAlign.get && (modNatAlignDist.get <= 1.U), "closeSubMags")
  private val notSigNaN_invalidExc = wrap(a.get.isInf && b.get.isInf && !eqSigns.get, "notSigNaN_invalidExc")
  private val notNaN_isInfOut = wrap(a.get.isInf || b.get.isInf, "notNaN_isInfOut")
  private val addZeros = wrap(a.get.isZero && b.get.isZero, "addZeros")
  private val notNaN_specialCase = wrap(notNaN_isInfOut.get || addZeros.get, "notNaN_specialCase")

  private val close_alignedSigA = wrap(
    Mux((0.S <= sDiffExps.get) && sDiffExps.get(0), a.get.sig << 2, 0.U) |
      Mux((0.S <= sDiffExps.get) && !sDiffExps.get(0), a.get.sig << 1, 0.U) |
      Mux((sDiffExps.get < 0.S), a.get.sig, 0.U),
    "close_alignedSigA"
  )
  private val close_sSigSum = wrap(close_alignedSigA.get.asSInt - (b.get.sig << 1).asSInt, "close_sSigSum")
  private val close_sigSum = wrap(Mux(close_sSigSum.get < 0.S, -close_sSigSum.get, close_sSigSum.get)(sigWidth + 1, 0), "close_sigSum")
  private val close_adjustedSigSum = wrap(close_sigSum.get << (sigWidth & 1), "close_adjustedSigSum")
  private val close_reduced2SigSum = wrap(orReduceBy2(close_adjustedSigSum.get), "close_reduced2SigSum")

  private val far_signOut = wrap(Mux(sDiffExps.get < 0.S, effSignB.get, a.get.sign), "far_signOut")
  private val far_sigLarger = wrap(Mux(sDiffExps.get < 0.S, b.get.sig, a.get.sig)(sigWidth - 1, 0), "far_sigLarger")
  private val far_sigSmaller = wrap(Mux(sDiffExps.get < 0.S, a.get.sig, b.get.sig)(sigWidth - 1, 0), "far_sigSmaller")
  private val far_mainAlignedSigSmaller = wrap((far_sigSmaller.get << 5) >> alignDist.get, "far_mainAlignedSigSmaller")
  private val far_reduced4SigSmaller = wrap(orReduceBy4(far_sigSmaller.get << 2), "far_reduced4SigSmaller")

  newStage()

  private val close_normDistReduced2 = wrap(countLeadingZeros(close_reduced2SigSum.get), "close_normDistReduced2")
  private val close_nearNormDist = wrap((close_normDistReduced2.get << 1)(alignDistWidth - 1, 0), "close_nearNormDist")
  private val close_sigOut = wrap(((close_sigSum.get << close_nearNormDist.get) << 1)(sigWidth + 2, 0), "close_sigOut")
  private val close_totalCancellation = wrap(!(close_sigOut.get((sigWidth + 2), (sigWidth + 1)).orR), "close_totalCancellation")
  private val close_notTotalCancellation_signOut = wrap(a.get.sign ^ (close_sSigSum.get < 0.S), "close_notTotalCancellation_signOut")

  private val far_roundExtraMask = wrap(lowMask(alignDist.get(alignDistWidth - 1, 2), (sigWidth + 5) / 4, 0), "far_roundExtraMask")
  private val far_alignedSigSmaller =
    wrap(
      Cat(far_mainAlignedSigSmaller.get >> 3, far_mainAlignedSigSmaller.get(2, 0).orR || (far_reduced4SigSmaller.get & far_roundExtraMask.get).orR),
      "far_alignedSigSmaller"
    )
  private val far_subMags = wrap(!eqSigns.get, "far_subMags")
  private val far_negAlignedSigSmaller =
    wrap(Mux(far_subMags.get, Cat(1.U, ~far_alignedSigSmaller.get), far_alignedSigSmaller.get), "far_negAlignedSigSmaller")
  private val far_sigSum = wrap((far_sigLarger.get << 3) + far_negAlignedSigSmaller.get + far_subMags.get, "far_sigSum")
  private val far_sigOut = wrap(Mux(far_subMags.get, far_sigSum.get, (far_sigSum.get >> 1) | far_sigSum.get(0))(sigWidth + 2, 0), "far_sigOut")

  private val notNaN_isZeroOut = wrap(addZeros.get || (!notNaN_isInfOut.get && closeSubMags.get && close_totalCancellation.get), "notNaN_isZeroOut")
  private val notNaN_signOut =
    wrap(
      (eqSigns.get && a.get.sign) ||
        (a.get.isInf && a.get.sign) ||
        (b.get.isInf && effSignB.get) ||
        (notNaN_isZeroOut.get && !eqSigns.get && notEqSigns_signZero.get) ||
        (!notNaN_specialCase.get && closeSubMags.get && !close_totalCancellation.get
          && close_notTotalCancellation_signOut.get) ||
        (!notNaN_specialCase.get && !closeSubMags.get && far_signOut.get),
      "notNaN_signOut"
    )
  private val common_sExpOut =
    wrap(
      Mux(closeSubMags.get || (sDiffExps.get < 0.S), b.get.sExp, a.get.sExp)
        - Mux(closeSubMags.get, close_nearNormDist.get, far_subMags.get).zext,
      "common_sExpOut"
    )
  private val common_sigOut = wrap(Mux(closeSubMags.get, close_sigOut.get, far_sigOut.get), "common_sigOut")

  io.invalidExc := isSigNaNRawFloat(a.get) || isSigNaNRawFloat(b.get) || notSigNaN_invalidExc.get
  io.rawOut.isInf := notNaN_isInfOut.get
  io.rawOut.isZero := notNaN_isZeroOut.get
  io.rawOut.sExp := common_sExpOut.get
  io.rawOut.isNaN := a.get.isNaN || b.get.isNaN
  io.rawOut.sign := notNaN_signOut.get
  io.rawOut.sig := common_sigOut.get
}

private class AddRecFN_Pipelined(expWidth: Int, sigWidth: Int) extends Module with PipelineHelper {
  override val desiredName = f"AddRecFN_Pipelined_${expWidth}_${sigWidth}"

  val io = IO(new Bundle {
    val subOp = Input(Bool())
    val a = Input(UInt((expWidth + sigWidth + 1).W))
    val b = Input(UInt((expWidth + sigWidth + 1).W))
    val roundingMode = Input(UInt(3.W))
    val detectTininess = Input(Bool())
    val out = Output(UInt((expWidth + sigWidth + 1).W))
    val exceptionFlags = Output(UInt(5.W))
  })

  private val subOp = wrap(io.subOp, "subOp")
  private val a = wrap(io.a, "a")
  private val b = wrap(io.b, "b")
  private val roundingMode = wrap(io.roundingMode, "roundingMode")
  private val detectTininess = wrap(io.detectTininess, "detectTininess")

  newStage()

  private val addRawFN = Module(new AddRawFN_Pipelined(expWidth, sigWidth))

  addRawFN.io.subOp := subOp.get
  addRawFN.io.a := rawFloatFromRecFN(expWidth, sigWidth, a.get)
  addRawFN.io.b := rawFloatFromRecFN(expWidth, sigWidth, b.get)
  addRawFN.io.roundingMode := roundingMode.get

  newStage() // to match with AddRawFN_Pipelined

  private val addRawFN_invalidExc = wrap(addRawFN.io.invalidExc, "addRawFN_invalidExc")
  private val addRawFN_rawOut = wrap(addRawFN.io.rawOut, "addRawFN_rawOut")

  newStage()

  private val roundRawFNToRecFN = Module(new RoundRawFNToRecFN(expWidth, sigWidth, 0))

  roundRawFNToRecFN.io.invalidExc := addRawFN_invalidExc.get
  roundRawFNToRecFN.io.infiniteExc := false.B
  roundRawFNToRecFN.io.in := addRawFN_rawOut.get
  roundRawFNToRecFN.io.roundingMode := roundingMode.get
  roundRawFNToRecFN.io.detectTininess := detectTininess.get

  private val roundRawFNToRecFN_out = wrap(roundRawFNToRecFN.io.out, "roundRawFNToRecFN_out")
  private val roundRawFNToRecFN_exceptionFlags = wrap(roundRawFNToRecFN.io.exceptionFlags, "roundRawFNToRecFN_exceptionFlags")

  // final stage to avoid increasing the critical path when wrapped elastic
  newStage()

  io.out := roundRawFNToRecFN_out.get
  io.exceptionFlags := roundRawFNToRecFN_exceptionFlags.get
}

private class AddFp_Pipelined(gen_fp: FloatingPoint) extends Module {
  override val desiredName = f"AddFp_Pipelined_${gen_fp.exponent_width}_${gen_fp.mantissa_width}"

  val io = IO(new Bundle {
    val in_a = Input(gen_fp)
    val in_b = Input(gen_fp)
    val out = Output(gen_fp)
  })

  private val in_a = io.in_a
  private val in_b = io.in_b
  private val out = io.out

  private val expWidth = gen_fp.exponent_width
  private val sigWidth = gen_fp.mantissa_width + 1

  private val addRecFN = Module(new AddRecFN_Pipelined(expWidth, sigWidth))

  addRecFN.io.subOp := false.B
  addRecFN.io.a := recFNFromFN(expWidth, sigWidth, in_a.asUInt)
  addRecFN.io.b := recFNFromFN(expWidth, sigWidth, in_b.asUInt)
  addRecFN.io.roundingMode := round_near_even
  addRecFN.io.detectTininess := true.B

  out := fNFromRecFN(expWidth, sigWidth, addRecFN.io.out).asTypeOf(out)
}

private class AddFp_Combinational(gen_fp: FloatingPoint) extends RawModule {
  override val desiredName = f"AddFp_Combinational_${gen_fp.exponent_width}_${gen_fp.mantissa_width}"

  val io = IO(new Bundle {
    val in_a = Input(gen_fp)
    val in_b = Input(gen_fp)
    val out = Output(gen_fp)
  })

  private val in_a = io.in_a
  private val in_b = io.in_b
  private val out = io.out

  private val expWidth = gen_fp.exponent_width
  private val sigWidth = gen_fp.mantissa_width + 1

  private val addRecFN = Module(new AddRecFN(expWidth, sigWidth))

  addRecFN.io.subOp := false.B
  addRecFN.io.a := recFNFromFN(expWidth, sigWidth, in_a.asUInt)
  addRecFN.io.b := recFNFromFN(expWidth, sigWidth, in_b.asUInt)
  addRecFN.io.roundingMode := round_near_even
  addRecFN.io.detectTininess := true.B

  out := fNFromRecFN(expWidth, sigWidth, addRecFN.io.out).asTypeOf(out)
}

private class MulRecFN_Pipelined(expWidth: Int, sigWidth: Int) extends Module with PipelineHelper {
  override val desiredName = f"MulRecFN_Pipelined_${expWidth}_${sigWidth}"

  val io = IO(new Bundle {
    val a = Input(UInt((expWidth + sigWidth + 1).W))
    val b = Input(UInt((expWidth + sigWidth + 1).W))
    val roundingMode = Input(UInt(3.W))
    val detectTininess = Input(Bool())
    val out = Output(UInt((expWidth + sigWidth + 1).W))
    val exceptionFlags = Output(UInt(5.W))
  })

  private val a = wrap(io.a, "a")
  private val b = wrap(io.b, "b")
  private val roundingMode = wrap(io.roundingMode, "roundingMode")
  private val detectTininess = wrap(io.detectTininess, "detectTininess")

  // first stage to avoid increasing the critical path when wrapped elastic
  newStage()

  private val mulRawFN = Module(new MulRawFN(expWidth, sigWidth))

  mulRawFN.io.a := rawFloatFromRecFN(expWidth, sigWidth, a.get)
  mulRawFN.io.b := rawFloatFromRecFN(expWidth, sigWidth, b.get)

  private val mulRawFn_invalidExc = wrap(mulRawFN.io.invalidExc, "mulRawFn_invalidExc")
  private val mulRawFn_rawOut = wrap(mulRawFN.io.rawOut, "mulRawFn_rawOut")

  newStage()

  private val roundRawFNToRecFN = Module(new RoundRawFNToRecFN(expWidth, sigWidth, 0))

  roundRawFNToRecFN.io.invalidExc := mulRawFn_invalidExc.get
  roundRawFNToRecFN.io.infiniteExc := false.B
  roundRawFNToRecFN.io.in := mulRawFn_rawOut.get
  roundRawFNToRecFN.io.roundingMode := roundingMode.get
  roundRawFNToRecFN.io.detectTininess := detectTininess.get

  private val roundRawFNToRecFN_out = wrap(roundRawFNToRecFN.io.out, "roundRawFNToRecFN_out")
  private val roundRawFNToRecFN_exceptionFlags = wrap(roundRawFNToRecFN.io.exceptionFlags, "roundRawFNToRecFN_exceptionFlags")

  // final stage to avoid increasing the critical path when wrapped elastic
  newStage()

  io.out := roundRawFNToRecFN_out.get
  io.exceptionFlags := roundRawFNToRecFN_exceptionFlags.get
}

private class MulFp_Pipelined(gen_fp: FloatingPoint) extends Module {
  override val desiredName = f"MulFp_Pipelined_${gen_fp.exponent_width}_${gen_fp.mantissa_width}"

  val io = IO(new Bundle {
    val in_a = Input(gen_fp)
    val in_b = Input(gen_fp)
    val out = Output(gen_fp)
  })

  private val in_a = io.in_a
  private val in_b = io.in_b
  private val out = io.out

  private val expWidth = gen_fp.exponent_width
  private val sigWidth = gen_fp.mantissa_width + 1

  private val mulRecFn = Module(new MulRecFN_Pipelined(expWidth, sigWidth))

  mulRecFn.io.a := recFNFromFN(expWidth, sigWidth, in_a.asUInt)
  mulRecFn.io.b := recFNFromFN(expWidth, sigWidth, in_b.asUInt)
  mulRecFn.io.roundingMode := round_near_even
  mulRecFn.io.detectTininess := true.B

  out := fNFromRecFN(expWidth, sigWidth, mulRecFn.io.out).asTypeOf(out)
}

private class MulFp_Combinational(gen_fp: FloatingPoint) extends RawModule {
  override val desiredName = f"MulFp_Combinational_${gen_fp.exponent_width}_${gen_fp.mantissa_width}"

  val io = IO(new Bundle {
    val in_a = Input(gen_fp)
    val in_b = Input(gen_fp)
    val out = Output(gen_fp)
  })

  private val in_a = io.in_a
  private val in_b = io.in_b
  private val out = io.out

  private val expWidth = gen_fp.exponent_width
  private val sigWidth = gen_fp.mantissa_width + 1

  private val mulRecFn = Module(new MulRecFN(expWidth, sigWidth))

  mulRecFn.io.a := recFNFromFN(expWidth, sigWidth, in_a.asUInt)
  mulRecFn.io.b := recFNFromFN(expWidth, sigWidth, in_b.asUInt)
  mulRecFn.io.roundingMode := round_near_even
  mulRecFn.io.detectTininess := true.B

  out := fNFromRecFN(expWidth, sigWidth, mulRecFn.io.out).asTypeOf(out)
}
