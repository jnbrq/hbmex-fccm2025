package sysc_tb

import hbmex.components.read_engine.ReadEngine_TB

object Emit extends App {
  def emitSyscTb() = {
    println("Emitting SystemVerilog files for SystemC test benches.")

    import scala.reflect.ClassTag

    import chisel3._

    def run(app: chext.TestBench): Unit = {
      println(f"    Emitting: '${app.getClass.getTypeName().stripSuffix("$")}'")
      app.main(Array.empty)
    }

    // Add other modules here
    import chext.amba.axi4.full.components.IdParallelizeNoReadBurst_TB
    import chext.ip.float.ElasticTop_TB

    import hbmex.components.read_engine.ReadEngine_TB
    import hbmex.components.spmv.{RowReduce_TB, Spmv_TB}
    import hbmex.components.stream.{ReadStream_TB, WriteStream_TB}

    run(IdParallelizeNoReadBurst_TB)
    run(ElasticTop_TB)

    run(ReadEngine_TB)
    run(RowReduce_TB)
    run(Spmv_TB)
    run(ReadStream_TB)
    run(WriteStream_TB)
  }

  emitSyscTb()
}
