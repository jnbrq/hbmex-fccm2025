package hdlinfo

import io.circe.{Encoder, Decoder}

case class PortDirection(val str: String)
object PortDirection {
  val none = PortDirection("none")
  val input = PortDirection("input")
  val output = PortDirection("output")
  val bidirectional = PortDirection("bidirectional")

  implicit val encodePortDirection: Encoder[PortDirection] =
    Encoder.encodeString.contramap[PortDirection](_.str)

  implicit val decodePortDirection: Decoder[PortDirection] =
    Decoder.decodeString.emap { str => Right(PortDirection(str)) }
}

case class PortKind(val str: String)
object PortKind {
  val none = PortKind("none")

  val clock = PortKind("clock")
  val reset = PortKind("reset")
  val asyncReset = PortKind("asyncReset")
  val data = PortKind("data")
  val interrupt = PortKind("interrupt")

  implicit val encodePortKind: Encoder[PortKind] =
    Encoder.encodeString.contramap[PortKind](_.str)

  implicit val decodePortKind: Decoder[PortKind] =
    Decoder.decodeString.emap { str => Right(PortKind(str)) }
}

case class PortSensitivity(val str: String)
object PortSensitivity {
  val none = PortSensitivity("none")

  val resetActiveHigh = PortSensitivity("resetActiveHigh")
  val resetActiveLow = PortSensitivity("resetActiveLow")

  val clockRising = PortSensitivity("clockRising")
  val clockFalling = PortSensitivity("clockFalling")

  val interruptHigh = PortSensitivity("interruptHigh")
  val interruptLow = PortSensitivity("interruptLow")
  val interruptRising = PortSensitivity("interruptRising")
  val interruptFalling = PortSensitivity("interruptFalling")

  implicit val encodePortSensitivity: Encoder[PortSensitivity] =
    Encoder.encodeString.contramap[PortSensitivity](_.str)

  implicit val decodePortSensitivity: Decoder[PortSensitivity] =
    Decoder.decodeString.emap { str => Right(PortSensitivity(str)) }
}

case class Port(
    val name: String,
    val direction: PortDirection,
    val kind: PortKind,
    val sensitivity: PortSensitivity = PortSensitivity.none,
    val isBus: Boolean = false,
    val busRange: Tuple2[Int, Int] = (0, 0),
    val frequencyMHz: Float = 100,
    val associatedClock: String = "clock",
    val associatedReset: String = "reset",
    val args: scala.collection.immutable.Map[String, TypedObject] =
      scala.collection.immutable.Map.empty
) {
  val isInterrupt = (kind == PortKind.interrupt)
  val isLevelInterrupt =
    (isInterrupt && (sensitivity == PortSensitivity.interruptLow || sensitivity == PortSensitivity.interruptHigh))
  val isEdgeInterrupt =
    (isInterrupt && (sensitivity == PortSensitivity.interruptRising || sensitivity == PortSensitivity.interruptFalling))
  val isRisingEdgeInterrupt = (isEdgeInterrupt && sensitivity == PortSensitivity.interruptRising)
  val isFallingEdgeInterrupt = (isEdgeInterrupt && sensitivity == PortSensitivity.interruptFalling)
  val isHighLevelInterrupt = (isLevelInterrupt && sensitivity == PortSensitivity.interruptHigh)
  val isLowLevelInterrupt = (isLevelInterrupt && sensitivity == PortSensitivity.interruptLow)

  val isClock = (kind == PortKind.clock)
  val isReset = (kind == PortKind.reset)
  val isData = (kind == PortKind.data)

  val isActiveHigh = (!isInterrupt && sensitivity == PortSensitivity.resetActiveHigh)
  val isActiveLow = (!isInterrupt && sensitivity == PortSensitivity.resetActiveLow)
}

import io.circe.syntax._
import io.circe.generic.auto._

private object PortTest extends App {
  println(PortSensitivity("not a well defined one"))
  println(
    Port("test", PortDirection.input, PortKind.clock, isBus = true, busRange = (12, 0)).asJson
  )
  println(
    Port(
      "test",
      PortDirection.input,
      PortKind.clock,
      PortSensitivity.resetActiveHigh,
      isBus = true,
      busRange = (12, 0)
    ).isActiveHigh
  )
  println(
    Port("test", PortDirection.input, PortKind.clock, isBus = true, busRange = (12, 0)).asJson
      .as[Port]
  )
  println(
    Port("test", PortDirection.output, PortKind.interrupt, isBus = true, busRange = (12, 0)).asJson
      .as[Port]
  )
}
