#!/bin/bash

echo "extracting Vivado projects"
cat fpga.tar.gz.* | tar -vxzf - -C "../"

echo "done."
