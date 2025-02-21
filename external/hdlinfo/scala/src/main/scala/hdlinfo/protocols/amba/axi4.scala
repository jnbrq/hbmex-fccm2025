package hdlinfo.protocols.amba.axi4

import hdlinfo.Registry
import hdlinfo.util.isPow2

/** AXI4 interface configuration.
  *
  * @param wId
  *   identification tag width
  * @param wAddr
  *   address width
  * @param wData
  *   data bus width
  * @param read
  *   enable read channels
  * @param write
  *   enable write channels
  * @param lite
  *   use AXI4-Lite variant
  * @param wUserReq
  *   data width for ARUSER and AWUSER (see p. A8-104 in ARM IHI 0022H.c)
  * @param wUserData
  *   user data width for RUSER and WUSER (see p. A8-104 in ARM IHI 0022H.c)
  * @param wUserResp
  *   user data width for RUSER and BUSER (see p. A8-104 in ARM IHI 0022H.c)
  */
case class Config(
    val wId: Int = 0,
    val wAddr: Int = 32,
    val wData: Int = 32,
    val read: Boolean = true,
    val write: Boolean = true,
    val lite: Boolean = false,
    val wUserAR: Int = 0,
    val wUserR: Int = 0,
    val wUserAW: Int = 0,
    val wUserW: Int = 0,
    val wUserB: Int = 0
) {
  require(wData >= 8)
  require(isPow2(wData))
  require(!lite || (wData == 32 || wData == 64))

  /** width of the strobe signal for the write data channel */
  val wStrobe = wData / 8
}

import io.circe.syntax._
import io.circe.generic.auto._

object register {
  def apply(): Unit = {
    Registry.register[Config]("hdlinfo.protocols.amba.axi4.Config")
  }
}
