package chext.elastic

import chisel3._
import chisel3.util._
import chisel3.experimental._
import scala.collection.mutable.ListBuffer

abstract class Join[T <: Data](val sink: ReadyValidIO[T]) extends AffectsChiselPrefix {
  private val sources = ListBuffer.empty[ReadyValidIO[Data]]
  protected val out: T = sink.bits

  /** Adds a new RV interface to join.
    *
    * @param sink
    * @return
    */
  def join[V <: Data](source: ReadyValidIO[V]): V = {
    sources.addOne(source)
    source.bits
  }

  protected def onJoin: Unit

  onJoin
  JoinUtils.join(sources.toSeq, sink)
}

private[elastic] object JoinUtils {

  /** Implements a join.
    *
    * @param sources
    * @param sink
    */
  def join[T <: Data](
      sources: Seq[ReadyValidIO[Data]],
      sink: ReadyValidIO[Data]
  ): Unit =
    prefix("mkJoin") {
      val allValid =
        VecInit(sources.map { _.valid }).reduceTree(_ && _)
      val fire = sink.ready && allValid
      sources.foreach { _.ready := fire }
      sink.valid := allValid
    }
}
