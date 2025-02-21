#ifndef D4E_XIL_H_INCLUDED
#define D4E_XIL_H_INCLUDED

#include <linux/limits.h>
#include <pthread.h>

#include "interface.h"

#ifdef __cplusplus
extern "C"
{
#endif

typedef uint8_t volatile *byte_mmptr_t;
typedef uint8_t volatile *uint8_mmptr_t;
typedef uint16_t volatile *uint16_mmptr_t;
typedef uint32_t volatile *uint32_mmptr_t;
typedef uint64_t volatile *uint64_mmptr_t;

struct d4e_xil_device
{
    /** device interface */
    struct d4e_device device;

    /** XDMA base path */
    char path_xdma_base[PATH_MAX];

    /** mutex for accesses */
    pthread_mutex_t mtx;

    /** file descriptor H2C */
    int fd_h2c;

    /** file descriptor C2H */
    int fd_c2h;

    /** file descriptor user block */
    int fd_user;

    /** mmapped memory block size */
    uint64_t mmap_size;

    /** mmapped memory block data */
    byte_mmptr_t mmap_ptr;
};

/**
 * @brief Opens a Xilinx FPGA device.
 *
 * @param device
 * @param path_xdma_base Expected format: `/dev/xdmaN`.
 * @param h2c_channel H2C channel.
 * @param c2h_channel C2H channel.
 * @return int -1 in case of error.
 */
int d4e_xil_device_open(
    struct d4e_xil_device *device,
    const char *path_xdma_base,
    int h2c_channel,
    int c2h_channel,
    uint64_t mmap_sz);

#ifdef __cplusplus
}
#endif

#endif /* D4E_XIL_H_INCLUDED */
