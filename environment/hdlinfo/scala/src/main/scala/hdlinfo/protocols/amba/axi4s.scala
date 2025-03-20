package hdlinfo.protocols.amba.axi4s

import hdlinfo.Registry

case class Config(
    val wData: Int,
    val onlyRV: Boolean = false,
    val wId: Int = 0,
    val wDest: Int = 0,
    val wUser: Int = 0
) {
  require(wData % 8 == 0)

  val wStrobe = wData / 8
  val wKeep = wStrobe
}

import io.circe.syntax._
import io.circe.generic.auto._

object register {
  def apply(): Unit = {
    Registry.register[Config]("hdlinfo.protocols.amba.axi4s.Config")
  }
}
