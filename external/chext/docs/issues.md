# `chext` Issues

## Pipelining

### Elastic Components

| Component Name      | Status                                                                                 |
| ------------------- | -------------------------------------------------------------------------------------- |
| elastic.Demux       | Pipelined already in FlexiMem. Suggestion: elastic.PipelinedDemux                      |
| elastic.Mux         | Probably not pipelinable. However, AXI modules using this one are in fact pipelinable. |
| elastic.Arbiter     | Pipelined already in FlexiMem. Suggestion: elastic.PipelinedArbiter                    |
| elastic.Distributor | Will be obsoleted.                                                                     |
| elastic.Replicate   | No need for pipelining.                                                                |
| elastic.Transform   | No need for pipelining.                                                                |

`elastic.Mux` requires centralized control which makes pipelining practically impossible.

### AXI components

Most AXI components use `elastic.Mux`, which is not pipelinable. However, AXI muxes can be easily made into a tree shape with AXI buffers in between.

AXI demux is more difficult to pipeline: we can still place smaller AXI demuxes in a tree; however, we should also modify the address decoding logic. For each demux, the address decoding logic becomes a disjunction of possible ports downstream, whic is a large and complicated logic function. Maybe, we can have instead a simple helper structure for encoding the address space? Think about this!

## Naming Conventions

`chext.amba.axi4` and `chext.elastic` have weird naming conventions.

```scala
class ElasticModule[T <: Data](gen: T) extends Module {
  val source = IO(Source(Decoupled(gen)))
  val sink = IO(Sink(Decoupled(gen)))
  // Source() and Sink() describe the ports from the perspective of the module.

  SourceBuffer(source) :=> SinkBuffer(sink)

  // If we had two module instances, however:
  m1.sink :=> m2.source // WTF? looks awful!
  SourceBuffer(m1.sink) :=> SinkBuffer(m2.source) // even worse!
}

class AxiModule(cfg: axi4.Config) extends Module {
  val s_axi = IO(axi4.Slave(cfg))
  val m_axi = IO(axi4.Master(cfg))
  // Slave() and Master() describe the ports from the perspective of the module.

  // I really do not like the following expressions:
  s_axi :=> m_axi
  SlaveBuffer(s_axi) :=> MasterBuffer(m_axi)

  // I read the a :=> b operator as: Master Interface a drives Slave Interface b.
  // However, s_axi :=> m_axi suggests otherwise.
  // Observe that the definitions of the slave/master buffers are consistent within themselves
  // for the examples above.

  // If we had two module instances with master/slave ports, we would have:
  m1.m_axi :=> m2.s_axi // that is fine!
  SlaveBuffer(m1.m_axi) :=> MasterBuffer(m2.s_axi) // OOPS!
}
```

So, what is the resolution to these problems:

1. Employ `LeftBuffer` and `RightBuffer`, that are strictly used in the `:=>` expression.
2. Keep the definitions of `MasterBuffer`, `SlaveBuffer`, `SourceBuffer`, and `SinkBuffer` to allow:

    ```scala
    class AxiModule(cfg: axi4.Config) extends Module {
      val s_axi = IO(axi4.Slave(cfg))
      val m_axi = IO(axi4.Master(cfg))
      
      private val s_axi_buffered_ = SlaveBuffer(s_axi)
      private val m_axi_buffered_ = MasterBuffer(m_axi)
    } 
    ```

3. Canonicalize the following syntaxes:

    ```scala
    // for elastic
    source :=> sink
    m1.sink :=> m2.source
    m1.sink :=> sink
    source :=> m1.source

    // for AXI (and similar)
    s_axi :=> m_axi
    m1.m_axi :=> m2.s_axi
    m1.m_axi :=> m_axi
    s_axi :=> m1.s_axi

    // also for all
    LeftBufer(m1.sink) :=> RightBuffer(m2.source)
    LeftBuffer(s_axi) :=> RightBuffer(m_axi)
    ```

4. Create a systematic for connection/buffer APIs. For example, would it work if we had duplicate definitions of `LeftBuffer` and `RightBuffer` coming from different packages?

## Decoupled/Irrevocable IO distinction, do we really need it?

Chisel uses separate types of Ready/Valid IO, which are identical in functionality and they differ only in semantics.
`chext` employs only the irrevocable IO semantics.

**We should not use separate Ready/Valid IO types: define `chext.ReadyValidIO(gen: T)` and do not rely on anything other than it.**

- Provide `DataView`s for Irrevocable/Decoupled IO interoperability.
- Use a custom queue implementation.
- Redefine `Source(...)` and `Sink(...)` so that you can write `Source(UInt(32.W))` instead of `Source(Decoupled(UInt(32.W)))`. The new version automatically becomes `chext.ReadyValidIO[UInt]`.

## Compatibility with the newer versions of Chisel

In the newer versions of Chisel, `<>` operator is almost deprecated or its behavior in relation to other components has changed.
Once you canonicalize the connection APIs, remove all instances of the `<>` operator!

## Naming convention for elastic modules

I am not really sure if source or sink are intuitive names. Compare the following examples:

```scala
class ElasticModule1[T <: Data](gen: T) extends Module {
  val source = IO(Source(Decoupled(gen)))
  val sink = IO(Sink(Decoupled(gen)))
}

class ElasticModule2[T <: Data](gen: T) extends Module {
  val input = IO(Input /* ?? */(Decoupled(gen)))
  val output = IO(Sink /* ?? */(Decoupled(gen)))
}
```

- "Input of a module" vs. "Source of a module"
- "Output of a module" vs. "Sink of a module"
