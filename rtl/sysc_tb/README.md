# SystemC testbenches

> **NOTE** Make sure that you have emitted the Verilog files for the SystemC testbench. \
By default, the git repository contains these files.
However, if you make changes to the RTL source code, they must be emitted again.

To run the testbench, please open a Bash shell in `${HBMEX_REPO}`, and write the following commands:

```bash
# activate the installation environment
# replace ... with the HBMex installation prefix
# please check the output of the installation script
. .../bin/activate-hbmex.sh

cd "${HBMEX_REPO}/rtl/sysc_tb"
mkdir build && cd build
cmake .. -G Ninja -D CMAKE_PREFIX_PATH="${HBMEX_PREFIX}" -D CMAKE_INSTALL_PREFIX="${HBMEX_PREFIX}"
ninja

# this command will run all the testbenches
bash run_all.sh
```

If you make changes to the RTL and re-emit the project, repeat the steps above.

**[Go back](../../README.md#step-2-runnning-the-systemc-testbenches) to the main document.**
