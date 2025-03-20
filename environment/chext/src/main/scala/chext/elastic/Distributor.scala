package chext.elastic

import chext.elastic
import elastic.internal

import chisel3._
import chisel3.util._

import elastic.ConnectOp._

class Distributor[T <: Data](
    val gen: T,
    val n: Int,
    val chooserFn: Chooser.ChooserFn,
    val isLastFn: T => Bool = (_: T) => true.B
) extends Module
    with internal.ChoosingModule {
  require(n > 0)
  override def desiredName: String = "elasticDistributor"

  val io = IO(new Bundle {
    val source = Source(Decoupled(gen))
    val sinks = Vec(n, Sink(Decoupled(gen)))
    val select = Sink(Irrevocable(genSelect))
  })

  private val source = io.source
  private val sinks = VecInit(io.sinks.map { SinkBuffer(_) })
  private val select = io.select

  // NOTE: Distributor employs a SinkBuffer to avoid a combinational
  // path from ready to valid at sinks [see below, the path happens over
  // the chooseFn(... ready ...)].
  // The downside is that the priority chooser does not play
  // well with this approach, as the high priority one might always
  // capture the data (in case there is a high-latency operation down stream,
  // it must be OK).
  // Is there a better way to implement the distributor?

  protected val chooser = chooserFn(VecInit(sinks.map { _.ready }))

  protected val sourceValid = source.valid
  protected val sourceLast = isLastFn(source.bits)
  protected val sourceReady = source.ready

  protected val selectValid = select.valid
  protected val selectReady = select.ready

  protected val sinkValid = Wire(Bool())
  protected val sinkReady = sinks(choice).ready

  protected def implementDataPlane() = {
    sinks.foreach { x => x.bits := source.bits }
    select.bits := choice

    sinks.zipWithIndex.foreach { case (x, i) =>
      x.valid := sinkValid && i.U === (choice)
    }
  }

  implementDataPlane()
  implementControlPlane()
  implementChoiceLogic()
}

object Distributor {
  def apply[T <: Data](
      source: ReadyValidIO[T],
      sinks: Seq[ReadyValidIO[T]],
      chooserFn: Chooser.ChooserFn,
      select: Option[ReadyValidIO[UInt]] = None,
      isLastFn: T => Bool = (_: T) => true.B
  ): Unit = {
    val Distributor = Module(
      new Distributor(
        chiselTypeOf(source.bits),
        sinks.length,
        chooserFn,
        isLastFn
      )
    )

    source :=> Distributor.io.source
    Distributor.io.sinks.zip(sinks).foreach { case (x, y) => x :=> y }

    select match {
      case None         => Disposed(Distributor.io.select)
      case Some(select) => Distributor.io.select :=> select
    }
  }
}
