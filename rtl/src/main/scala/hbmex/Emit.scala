package hbmex

import scala.sys.process._
import java.io.File

private object FileUtils {
  def listFiles(dirPath: String): Seq[File] = {
    val dir = new File(dirPath)
    if (dir.exists() && dir.isDirectory()) {
      dir.listFiles().toSeq
    } else
      Seq.empty
  }
}

object Emit extends App {
  def emitSvVivado() = {
    println("Emitting SystemVerilog files for the Vivado project.")

    import scala.reflect.ClassTag

    import chisel3._
    import hbmex.experiments._

    def emit[M <: RawModule](args: Any*)(implicit tag: ClassTag[M]): Unit = {
      println(f"    Emitting: '${tag.runtimeClass.getTypeName()}'")
      emitVerilog(
        tag //
          .runtimeClass
          .getDeclaredConstructor(args.map(_.getClass): _*)
          .newInstance(args: _*)
          .asInstanceOf[RawModule],
        Array("--target-dir", "./emit/")
      )
    }

    // Add other modules here
    emit[ReadEngineExp0](ReadEngineExp0Config())
    emit[ReadEngineExp1](ReadEngineExp1Config())

    emit[SpmvExp0](SpmvExp0Config())
    emit[SpmvExp1](SpmvExp1Config())
    emit[SpmvExp2](SpmvExp2Config())
    emit[SpmvExp3](SpmvExp3Config())
  }

  def convertVivadoSvToV() = {
    println("Converting SystemVerilog files to Verilog files (the block designer does not support SystemVerilog modules).")

    def svToV(files: Seq[File]) = {
      files.foreach {
        case (file) => {
          val inFile = file
          val outFile = new File(file.getParentFile(), file.getName().stripSuffix(".sv") + ".v")

          println(f"    Converting: '${inFile.getAbsolutePath()}'")
          Process(Seq("sv2v", inFile.getAbsolutePath())).#>(outFile).run()
        }
      }
    }

    svToV(FileUtils.listFiles("./emit/").filter(_.getName().matches("""^ReadEngineExp\d*\.sv$""")))
    svToV(FileUtils.listFiles("./emit/").filter(_.getName().matches("""^SpmvExp\d*\.sv$""")))
  }

  emitSvVivado()
  convertVivadoSvToV()
}
