package hdlinfo

import io.circe.syntax._
import io.circe.generic.auto._
import hdlinfo.protocols.amba.{axi4, axi4s}

object Test1 extends App {

  val module = Module(
    "basicMemory",
    Seq(
      Port(
        "clock",
        PortDirection.input,
        PortKind.clock,
        PortSensitivity.clockRising
      ),
      Port(
        "reset",
        PortDirection.input,
        PortKind.reset,
        PortSensitivity.resetActiveHigh
      )
    ),
    Seq(
      Interface(
        "s_axi",
        InterfaceRole.slave,
        InterfaceKind.axi4,
        args = Map(
          "config" -> TypedObject(axi4.Config())
        )
      )
    ),
    args = Map(
      "somePort" -> TypedObject(
        Port(
          "clock",
          PortDirection.input,
          PortKind.clock,
          PortSensitivity.clockRising,
          args = Map(
            "otherPort" -> TypedObject(
              Port("bla", PortDirection("bla"), PortKind("bla"))
            )
          )
        )
      )
    )
  )

  println(module.asJson)
}
