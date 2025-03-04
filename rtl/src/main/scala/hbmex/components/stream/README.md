# Stream Modules

This folder contains the following modules (under package `hbmex.components.stream`):

1. `Downscale`: Converts a wide stream of data to a narrower stream of data.
2. `MemAdapter`: Exposes ready-valid interfaces over memory-mapped IO accessed over AXI4-Lite.
3. `ReadStream`: Reads a memory region (accessed over AXI4) and streams it to a ready-valid interface.
4. `WriteStream`: Writes a memory region (accessed over AXI4) by streaming a ready-valid interface.

These modules will be eventually incorporated in Chext (`chext.ip.stream` and `chext.elastic`).
