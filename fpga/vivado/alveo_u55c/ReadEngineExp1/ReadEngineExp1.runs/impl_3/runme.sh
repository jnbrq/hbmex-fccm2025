#!/bin/sh

# 
# Vivado(TM)
# runme.sh: a Vivado-generated Runs Script for UNIX
# Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
# Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
# 

if [ -z "$PATH" ]; then
  PATH=/alpha/tools/Xilinx/Vitis/2024.1/bin:/alpha/tools/Xilinx/Vivado/2024.1/bin
else
  PATH=/alpha/tools/Xilinx/Vitis/2024.1/bin:/alpha/tools/Xilinx/Vivado/2024.1/bin:$PATH
fi
export PATH

if [ -z "$LD_LIBRARY_PATH" ]; then
  LD_LIBRARY_PATH=
else
  LD_LIBRARY_PATH=:$LD_LIBRARY_PATH
fi
export LD_LIBRARY_PATH

HD_PWD='/janberq/repos/jnbrq/hbmex/fpga/vivado/alveo_u55c/ReadEngineExp1/ReadEngineExp1.runs/impl_3'
cd "$HD_PWD"

HD_LOG=runme.log
/bin/touch $HD_LOG

ISEStep="./ISEWrap.sh"
EAStep()
{
     $ISEStep $HD_LOG "$@" >> $HD_LOG 2>&1
     if [ $? -ne 0 ]
     then
         exit
     fi
}

# pre-commands:
/bin/touch .write_bitstream.begin.rst
EAStep vivado -log bd_top_wrapper.vdi -applog -m64 -product Vivado -messageDb vivado.pb -mode batch -source bd_top_wrapper.tcl -notrace


