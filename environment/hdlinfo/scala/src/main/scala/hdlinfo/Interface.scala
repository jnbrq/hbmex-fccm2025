package hdlinfo

import io.circe.{Encoder, Decoder}

import io.circe.syntax._
import io.circe.generic.auto._

case class InterfaceRole(val str: String)
object InterfaceRole {
  val none = InterfaceRole("none")

  val monitor = InterfaceRole("monitor")

  val master = InterfaceRole("master")
  val slave = InterfaceRole("slave")

  val producer = InterfaceRole("producer")
  val consumer = InterfaceRole("consumer")

  implicit val encodeInterfaceRole: Encoder[InterfaceRole] =
    Encoder.encodeString.contramap[InterfaceRole](_.str)

  implicit val decodeInterfaceRole: Decoder[InterfaceRole] =
    Decoder.decodeString.emap { str => Right(InterfaceRole(str)) }
}

case class InterfaceKind(val str: String)

object InterfaceKind {
  val axi4 = InterfaceKind("axi4")

  def readyValid(bundleName: String): InterfaceKind = InterfaceKind(f"readyValid$$${bundleName}")

  implicit val encodeInterfaceKind: Encoder[InterfaceKind] =
    Encoder.encodeString.contramap[InterfaceKind](_.str)

  implicit val decodeInterfaceKind: Decoder[InterfaceKind] =
    Decoder.decodeString.emap { str => Right(InterfaceKind(str)) }
}

case class Interface(
    val name: String,
    val role: InterfaceRole,
    val kind: InterfaceKind,
    val associatedClock: String = "clock",
    val associatedReset: String = "reset",
    val args: scala.collection.immutable.Map[String, TypedObject] =
      scala.collection.immutable.Map.empty
)
