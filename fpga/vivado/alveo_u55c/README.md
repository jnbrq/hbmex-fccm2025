# Synthesizing the Bitstreams for Alveo U55C using Vivado 2024.1

**Step 1:** If you have created the RTL in the previous steps, you should copy the generated Verilog files (`.v`) to the Vivado sources directory, for each project. The emitted files are in `${HBMEX_REPO}/rtl/emit/`, the project source files are in `${HBMEX_REPO}/fpga/vivado/alveo_u55c/<proj_name>/<proj_name>.srcs/sources_1/imports/`.

Projects and the names of the RTL files are:

| Vivado Project Name `<proj_name>`   | Verilog File     | Description        |
|-------------------------------------|------------------|--------------------|
| ReadEngineExp0                      | ReadEngineExp0.v | Figure 6.          |
| ReadEngineExp0_noReorder            | ReadEngineExp0.v | Figure 6.          |
| ReadEngineExp0_noReorderNoLookahead | ReadEngineExp0.v |                    |
| ReadEngineExp1                      | ReadEngineExp1.v | Figure 7.          |
| SpmvExp1                            | SpmvExp1.v       | Figures 10 and 11. |
| SpmvExp2                            | SpmvExp2.v       | Figures 10 and 11. |
| SpmvExp3                            | SpmvExp3.v       | Figures 10 and 11. |

**Step 2:** Make sure that Vivado binaries are available in the `$PATH`:
```bash
# replace `$XILINX_ROOT` with the installation path
. $XILINX_ROOT/Vivado/2024.1/settings64.sh
```

**Step 3:** Open and start the runs for each project in `fpga/vivado/alveo_u55c/`:
```bash
vivado "${HBMEX_REPO}/fpga/vivado/alveo_u55c/<proj_name>/*.xpr"
```

> **NOTE:** For each project, we have 3 implementation runs with different parameters. You can start the default run only to save time.

**[Go back](../../../README.md#step-3-synthesizing-the-bitstreams) to the main document.**
