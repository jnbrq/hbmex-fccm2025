# Read Engine Experiments

Read engine experiments use the `hbmex.components.read_engine.ReadEngine` module to generate a stream of AXI read transactions.
They do not use the `hbmex.components.stripe.Stripe` module, the software generates an address stream that is distributed among PCs.

## ReadEngineExp0

Connected directly to the HBM IP slave interface.
Exposes an AXI3-compatible master interface with 6-bit IDs.

Used for generating:

1. All data series in Figure 6.
2. Blue and green data series in Figure 7.

## ReadEngineExp1

Connected to the RAMA IP.
Exposes an AXI4 master interface with 6-bit IDs.

Used for generating:

1. Orange data series in Figure 7.

# SpMV Experiments

SpMV experiments use the `hbmex.components.spmv.Spmv` to benchmark SpMV operations.
They also feature the `hbmex.components.stripe.Stripe` module to distribute memory requests among PCs
and `hbmex.components.stream.MemAdapter` to interface with the software.

All the experiments use the same striping scheme:

```scala
  val stripeTransformations = Seq(
    Seq(33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
    Seq(33, 32, 31, 30, 14, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 29, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
    Seq(33, 32, 31, 15, 14, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 30, 29, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
    Seq(33, 32, 16, 15, 14, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 31, 30, 29, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
    Seq(33, 17, 16, 15, 14, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 32, 31, 30, 29, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
    Seq(18, 17, 16, 15, 14, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 33, 32, 31, 30, 29, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,

    // for failsafe
    Seq(33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse,
    Seq(33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0).reverse
  )
```

## SpmvExp0

This experiment is used only for development purposes and not included in the paper.
It exposes an AXI3 interface that directly drives the HBM IP slave interface.

## SpmvExp1

This experiment uses the following modules:

1. `hbmex.components.spmv.Spmv`
2. `hbmex.components.stripe.Stripe`
3. `hbmex.components.stream.MemAdapter`

It exposes an AXI4-interface connected to the RAMA IP.

Used for generating:

1. Orange data series in Figures 10 and 11.

## SpmvExp2

This experiment uses the following modules:

1. `hbmex.components.spmv.Spmv`
2. `hbmex.components.stripe.Stripe`
3. `hbmex.components.stream.MemAdapter`
4. `chext.amba.axi4.full.components.IdParallelizeNoReadBurst`

It exposes an AXI3 interface (with 6-bit IDs) that drives the HBM IP slave interface.

Used for generating:

1. Blue data series in Figures 10 and 11.

## SpmvExp3

This experiment uses the following modules:

1. `hbmex.components.spmv.Spmv`
2. `hbmex.components.stripe.Stripe`
3. `hbmex.components.stream.MemAdapter`
4. `chext.amba.axi4.full.components.IdParallelizeNoReadBurst`
5. `hbmex.components.enhance.Enhance`

It exposes an AXI3 interface (with 3-bit IDs) that drives the HBM IP slave interface.
The `Enhance` module makes sure that the requests targeting the same PC have the same ID to avoid interconnect stalls.

Used for generating:

1. Green data series in Figures 10 and 11.

# Emitting Verilog files to be used in the Vivado project

Please run the `Emit` object in `Emit.scala`.You
