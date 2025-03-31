#!/bin/bash

echo "extracting SpMV workloads (CSR files)"
cat workloads.tar.gz.* | tar -vxzf - -C "../sw/workloads/"

echo "done."
