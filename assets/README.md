# Pre-built Assets

Downloading and extracting the assets:

```bash
cd "${HBMEX_REPO}/assets"

# first, download the archive files
bash ./download.sh

# extract the workloads, CSR files will be rewritten
bash ./extract_workloads.sh


# extract the FPGA assets that contain the complete Vivado projects
# including DCPs and other intermediate files.
# WARNING: this will OVERWRITE the changes on the vivado projects, be careful!
bash ./extract_fpga.sh
```

**[Go back](../sw/README.md#spmv-experiments) to `sw` document.**
**[Go back](../README.md#pre-built-assets) to the main document.**
