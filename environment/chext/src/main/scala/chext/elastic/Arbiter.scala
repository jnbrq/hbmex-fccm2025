package chext.elastic

import chext.elastic
import elastic.internal

import chisel3._
import chisel3.util._

import elastic.ConnectOp._

class BasicArbiter[T <: Data](
    val gen: T,
    val n: Int,
    val chooserFn: Chooser.ChooserFn
) extends Module {
  require(n > 0)
  val genSelect = UInt(chisel3.util.log2Up(n).W)

  override def desiredName: String = "elasticBasicArbiter"

  val io = IO(new Bundle {
    val sources = Vec(n, Source(Decoupled(gen)))
    val sink = Sink(Decoupled(gen))
    val select = Sink(Irrevocable(genSelect))
  })

  private val sources = io.sources

  // TODO do not use buffers, try to use eagerFork-like structure?
  private val sink = elastic.SinkBuffer(io.sink)
  private val select = elastic.SinkBuffer(io.select)

  private val chooser = chooserFn(VecInit(sources.map { _.valid }))
  private val choice = chooser.choice

  private val fire = sources(choice).valid && sink.ready && select.ready

  sink.valid := fire
  select.valid := fire

  sink.bits := sources(choice).bits
  select.bits := choice

  sources.zipWithIndex.foreach { case (x, i) =>
    x.ready := fire && i.U === (choice)
  }

  when(fire) {
    chooser.updateState
  }
}

object BasicArbiter {
  def apply[T <: Data](
      sources: Seq[ReadyValidIO[T]],
      sink: ReadyValidIO[T],
      chooserFn: Chooser.ChooserFn,
      select: Option[ReadyValidIO[UInt]] = None
  ): Unit = {
    val arbiter = Module(
      new BasicArbiter(
        chiselTypeOf(sources(0).bits),
        sources.length,
        chooserFn
      )
    )

    sources.zip(arbiter.io.sources).foreach { case (x, y) => x :=> y }
    arbiter.io.sink :=> sink

    select match {
      case None         => Disposed(arbiter.io.select)
      case Some(select) => arbiter.io.select :=> select
    }
  }
}

@deprecated("This arbiter is currently deprecated and fails.")
class Arbiter[T <: Data](
    val gen: T,
    val n: Int,
    val chooserFn: Chooser.ChooserFn,
    val isLastFn: T => Bool = (_: T) => true.B
) extends Module
    with internal.ChoosingModule {
  require(n > 0)
  override def desiredName: String = "elasticArbiter"

  val io = IO(new Bundle {
    val sources = Vec(n, Source(Decoupled(gen)))
    val sink = Sink(Decoupled(gen))
    val select = Sink(Irrevocable(genSelect))
  })

  private val sources = io.sources
  private val sink = io.sink
  private val select = io.select

  protected val chooser = chooserFn(VecInit(sources.map { _.valid }))

  protected val sourceValid = sources(choice).valid
  protected val sourceLast = isLastFn(sources(choice).bits)
  protected val sourceReady = Wire(Bool())

  protected val selectValid = select.valid
  protected val selectReady = select.ready

  protected val sinkValid = sink.valid
  protected val sinkReady = sink.ready

  protected def implementDataPlane() = {
    sink.bits := sources(choice).bits
    select.bits := choice

    sources.zipWithIndex.foreach { case (x, i) =>
      x.ready := sourceReady && i.U === (choice)
    }
  }

  implementDataPlane()
  implementControlPlane()
  implementChoiceLogic()
}

object Arbiter {
  def apply[T <: Data](
      sources: Seq[ReadyValidIO[T]],
      sink: ReadyValidIO[T],
      chooserFn: Chooser.ChooserFn,
      select: Option[ReadyValidIO[UInt]] = None,
      isLastFn: T => Bool = (_: T) => true.B
  ): Unit = {
    val arbiter = Module(
      new Arbiter(
        chiselTypeOf(sources(0).bits),
        sources.length,
        chooserFn,
        isLastFn
      )
    )

    sources.zip(arbiter.io.sources).foreach { case (x, y) => x :=> y }
    arbiter.io.sink :=> sink

    select match {
      case None         => Disposed(arbiter.io.select)
      case Some(select) => arbiter.io.select :=> select
    }
  }
}
