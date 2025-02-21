package chext

import chisel3._
import chisel3.reflect.DataMirror

object exportIO {
  def module(parentModule: Module, childModule: Module) = {
    val ports = DataMirror.modulePorts(childModule)

    ports.foreach {
      case (portName, portData) => {
        if (!(portData.isInstanceOf[Clock] || portData.isInstanceOf[Reset])) {
          IO(chiselTypeOf(portData)).suggestName(portName) <> portData
        }
      }
    }
  }

  def rawModule(parentModule: RawModule, childModule: RawModule) = {
    val ports = DataMirror.modulePorts(childModule)

    ports.foreach {
      case (portName, portData) => {
        IO(chiselTypeOf(portData)).suggestName(portName) <> portData
      }
    }
  }
}

private object emitHdlinfo {
  def apply(module: hdlinfo.Module, targetDir: String): Unit = {
    import io.circe.syntax._
    import io.circe.generic.auto._
    import java.io.PrintWriter

    val pw = new PrintWriter(f"${targetDir}/${module.name}.hdlinfo.json")
    pw.write(module.asJson.toString())
    pw.close()
  }
}

trait HasHdlinfoModule extends RawModule {
  def hdlinfoModule: hdlinfo.Module
}

trait TestBench extends App {
  private val _pkgName = Option(this.getClass.getPackage).map(_.getName).getOrElse(".")

  def ns(x: String): String = f"${_pkgName}.${x}".stripPrefix(".")

  def emit[T <: HasHdlinfoModule](genModule: => T): Unit = {
    val pkgPath = _pkgName.replace('.', '/')
    val hdlPath = f"./sysc_tb/${pkgPath}/hdl/"
    var hdlinfoModule: hdlinfo.Module = null
    emitVerilog(
      {
        val module = genModule
        hdlinfoModule = module.hdlinfoModule
        module
      },
      Array("--target-dir", hdlPath)
    )
    emitHdlinfo(hdlinfoModule, hdlPath)
  }
}
