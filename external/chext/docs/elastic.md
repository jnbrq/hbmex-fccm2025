# `chext.elastic` package

Elastic components mainly consist of:

1. Join (and Zip)
2. Fork
3. Multiplexer
4. Demultiplexer
5. Arbiter
6. Distributor

The elastic handshake protocol consists of Ready/Valid signals, which is the standard used by Chisel.
To avoid combinational loops, all the modules provided by the library employs "A valid signal MUST NOT depend combinationally on the corresponding ready signal".
In the implementation, modules enforce this by adding `SinkBuffer` where necessary.

## Buffers and Module Declaration

The example below introduces a basic module declaration with elastic interfaces.
It also shows how buffers are declared.

Buffers add a latency of 1 clock cycle.
They are typically used when:

1. Backpressure from a slow datapath also stalls the computation in a otherwise fast datapath. By inserting buffers on the slow datapath can unblock the fast datapath and increase the performance.
2. In case an interface's valid signal depends combinationally on the same interface's ready signal, a buffer can break the combinational path.

```scala
import chisel3._
import chisel3.util._

// import the package as `elastic`
import chext.elastic

import elastic.{
  Sink,
  Source,
  SinkBuffer,
  SourceBuffer
}

// defines the :=> operator for elastic interfaces
import elastic.ConnectOp._

class MyModule extends Module {
  // `Source` declares a source for documentation purposes.
  val source = IO(Source(Decoupled(UInt(32.W))))

  // Same goes for `Sink`.
  val sink = IO(Sink(Decoupled(UInt(32.W))))

  // :=> connects Ready/Valid interfaces
  // the source interface appears on the right, and
  // the sink interface appears on the left.
  source :=> sink

  // `SourceBuffer` places a buffer just after the source.
  SourceBuffer(source) :=> sink

  // `SinkBuffer` places a buffer just before the sink.
  source :=> SinkBuffer(sink)

  // it is possible to set the capacity of the buffer,
  // which is 2 in this case.
  source :=> SinkBuffer(sink, 2)

  // `SinkBuffer.irrevocable` and `SinkBuffer.decoupled` enforces
  // the type of the resulting interface. Same goes for
  // the `SourceBuffer`.
}

```

## Join

```scala
import chisel3._
import chisel3.util._
import chext.elastic

import elastic._
import elastic.ConnectOp._

class ElasticAdder extends Module {
  val source1 = IO(Source(Decoupled(UInt(32.W))))
  val source2 = IO(Source(Decoupled(UInt(32.W))))

  val sink = IO(Sink(Decoupled(UInt(32.W))))
  
  new elastic.Join(sink) {
    protected def onJoin: Unit = {
      // joins sources 1 and 2, and calculates the output
      // by adding the operands
      out := join(source1) + join(source2)
    }
  }
}
```

## Fork

Implements an eager fork.

```scala
import chisel3._
import chisel3.util._
import chext.elastic

import elastic._

class ElasticSplitter extends Module {
  val source = IO(Source(Decoupled(UInt(32.W))))

  val sinkHI = IO(Sink(Decoupled(UInt(16.W))))
  val sinkLO = IO(Sink(Decoupled(UInt(16.W))))
  val sink = IO(Sink(Decoupled(UInt(32.W))))
  
  new elastic.Fork(source) {
    protected def onFork: Unit = {
      // extract the high-order bits and connect to `sinkHI`
      fork(in(15, 8)) :=> sinkHI

      // extract the low-order bits and connect to `sinkLO`
      fork(in(7, 0)) :=> sinkLO

      // also keep the input as-is
      fork() :=> sink
    }
  }
}
```

## Multiplexer

```scala
import chisel3._
import chisel3.util._
import chext.elastic

import elastic._

class WriteRequest extends Bundle {
  val addr = UInt(32.W)
  val data = UInt(32.W)
}

class ElasticMultiplexer extends Module {
  val portSelSource = IO(Source(Decoupled(UInt(2.W))))
  val writeRequestSources = IO(Vec(4, Source(Decoupled(new WritePacket))))
  val writeRequestSink = IO(Sink(Decoupled(new WritePacket)))

  /* choose a write request port and forward it according to select */
  elastic.Mux(
    writeRequestSources,
    writeRequestSink,
    portSelSource
  )
}
```

## Demultiplexer

```scala
import chisel3._
import chisel3.util._
import chext.elastic

import elastic._

// Each packet carries data and a destination
class Packet extends Bundle {
  val data = UInt(32.W)
  val dest = UInt(2.W)
}

class ElasticRouter extends Module {
  val source = IO(Source(Decoupled(new Packet)))
  val sinks = IO(Vec(4, Sink(Decoupled(UInt(32.W)))))

  private val data = Wire(Decoupled(UInt(32.W)))
  private val select = Wire(Decoupled(UInt(2.W)))
  
  new Fork(source) {
    protected def onFork: Unit = {
      fork(in.data) :=> data
      fork(in.dest) :=> select
    }
  }

  elastic.Demux(
    data,
    sinks,
    select
  )
}
```

## Arbiter

```scala
import chisel3._
import chisel3.util._
import chext.elastic

import elastic._

// Elastic PE performs a very long computation.
class ElasticPE extends Module {
  val source = IO(Source(Decoupled(UInt(32.W))))
  val sink = IO(Sink(Decoupled(UInt(32.W))))

  private val source_ = SourceBuffer.irrevocable(source)
  private val sink_ = SinkBuffer.irrevocable(sink)

  private val working_ = RegInit(false.B)
  private val counter_ = RegInit(0.U)

  source_.nodeq()
  sink_.noenq()

  when (!working_) {
    when (source_.valid) {
      working_ := true.B
      counter_ := 8.U // takes 8 cycles
    }
  }.otherwise {
    when (counter_ === 0.U) {
      when (sink_.ready) {
        working_ := false.B
        sink_.enq(source_.deq() + 10.U /* our complex result */)
      }
    }.otherwise {
      counter_ = counter_ - 1.U
    }
  }
}

class ElasticArbiter extends Module {
  // multiple sources share the same PE
  val sources = IO(Vec(4, Source(Decoupled(UInt(32.W)))))
  val sinks = IO(Vec(4, Sink(Decoupled(UInt(32.W)))))

  private val pe = Module(new ElasticPE)
  private val select = Wire(Decoupled(UInt(2.W)))
  
  elastic.Arbiter(
    sources,
    pe.source,
    Chooser.rr,
    select
  )

  elastic.Demux(
    pe.sink,
    sinks,
    select
  )
}
```

## Distributor

## Transform

## Replicate

## Arrival
