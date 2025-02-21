/**
 * @file xil.c
 * @author Canberk Sönmez (canberk.sonmez.409@gmail.com)
 * @brief
 * @date 2023-06-29
 *
 * @note We do not do extensive error checking for pthread calls.
 *
 * Copyright (c) Canberk Sönmez 2023
 *
 */

#define _LARGEFILE64_SOURCE
#include <unistd.h>
#include <poll.h>
#include <fcntl.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/eventfd.h>
#include <sys/mman.h>

#include <util/misc.h>
#include <d4e/xil.h>
#include <error/assert.h>
#include <error/error.h>
#include <error/perr.h>

static int xil_interrupt_open(struct d4e_device *device, uint64_t interrupt_id)
{
    E_ASSERT(device != NULL);
    struct d4e_xil_device *xil_device = container_of(device, struct d4e_xil_device, device);

    char path_buffer[PATH_MAX + 128 /* to silence compiler checks */];
    sprintf(path_buffer, "%s_events_%d", xil_device->path_xdma_base, (int)interrupt_id);
    int fd = open(path_buffer, O_RDONLY);
    E_PERR_IF(fd == -1, "open-xdma_events", 0, error0);

    return fd;

error0:
    return -1;
}

static int xil_interrupt_close(struct d4e_device *device, int fd)
{
    E_ASSERT(device != NULL);
    struct d4e_xil_device *xil_device = container_of(device, struct d4e_xil_device, device);

    close(fd);

    return 0;
}

static int xil_interrupt_ack(struct d4e_device *device, int fd)
{
    E_ASSERT(device != NULL);
    struct d4e_xil_device *xil_device = container_of(device, struct d4e_xil_device, device);

    uint32_t buffer;

    {
        ssize_t result = read(fd, &buffer, sizeof(uint32_t));
        E_PERR_IF(result == -1, "read-xil_events", 0, error0);
        E_ERR_IF(result != sizeof(uint32_t), "read-xil_events", 0, error0);
    }

    return 0;

error0:
    return -1;
}

static int xil_interrupt_wait(struct d4e_device *device, int fd)
{
    return xil_interrupt_ack(device, fd);
}

#include <inttypes.h>

#define XIL_LOG_DMA_PARAMS                                                    \
    printf("%s: dest: 0x%016" PRIx64 " | src: 0x%016" PRIx64 " | size: %d\n", \
           __func__, (uint64_t)dest, (uint64_t)src, (int)size)

#define XIL_USE_CHUNKS
#define XIL_CHUNKSZ (512ull << 20)

static int xil_dma_h2d_single(struct d4e_xil_device *xil_device, d4e_addr_t dest, void const *src, size_t size)
{
    int r = 0;

    {
        loff_t result = lseek64(xil_device->fd_h2c, dest, SEEK_SET);
        E_PERR_IF(result == -1, "lseek64", r = -1, end);
        E_ASSERT(result == dest);
    }

    {
        ssize_t result = write(xil_device->fd_h2c, (void const *)src, size);
        E_PERR_IF(result == -1, "write", r = -1, end);
        E_ERR_IF(result != size, "write", r = -1, end);
    }

end:
    return r;
}

static int xil_dma_d2h_single(struct d4e_xil_device *xil_device, void const *dest, d4e_addr_t src, size_t size)
{
    int r = 0;

    {
        loff_t result = lseek64(xil_device->fd_c2h, src, SEEK_SET);
        E_PERR_IF(result == -1, "lseek64", r = -1, end);
        E_ASSERT(result == src);
    }

    {
        ssize_t result = read(xil_device->fd_c2h, (void *)dest, size);
        E_PERR_IF(result == -1, "read", r = -1, end);
        E_ERR_IF(result != size, "read", r = -1, end);
    }

end:
    return r;
}

static int xil_dma_h2d(struct d4e_device *device, d4e_addr_t dest, void const *src, size_t size)
{
    E_ASSERT(device != NULL);
    struct d4e_xil_device *xil_device = container_of(device, struct d4e_xil_device, device);

    int r = 0;
    pthread_mutex_lock(&xil_device->mtx);

#if !defined(XIL_USE_CHUNKS)
    r = xil_dma_h2d_single(xil_device, dest, src, size);
#else
    d4e_addr_t dd = dest;
    char const *ss = (char const *)src;

    for (ssize_t s = size; s > 0; s -= XIL_CHUNKSZ)
    {
        size_t sz = s >= XIL_CHUNKSZ ? XIL_CHUNKSZ : s;
        r = xil_dma_h2d_single(xil_device, dd, ss, sz);
        if (r < 0)
            goto end;
        ss += sz;
        dd += sz;
    }
#endif

end:
    pthread_mutex_unlock(&xil_device->mtx);

    return r;
}

static int xil_dma_d2h(struct d4e_device *device, void *dest, d4e_addr_t src, size_t size)
{
    E_ASSERT(device != NULL);
    struct d4e_xil_device *xil_device = container_of(device, struct d4e_xil_device, device);

    int r = 0;
    pthread_mutex_lock(&xil_device->mtx);

#if !defined(XIL_USE_CHUNKS)
    r = xil_dma_d2h_single(xil_device, dest, src, size);
#else
    char *dd = (char *)dest;
    d4e_addr_t ss = src;

    for (ssize_t s = size; s > 0; s -= XIL_CHUNKSZ)
    {
        size_t sz = s >= XIL_CHUNKSZ ? XIL_CHUNKSZ : s;
        r = xil_dma_d2h_single(xil_device, dd, ss, sz);
        if (r < 0)
            goto end;
        dd += sz;
        ss += sz;
    }
#endif

end:
    pthread_mutex_unlock(&xil_device->mtx);

    return r;
}

static uint32_t xil_reg_read32(struct d4e_device *device, d4e_addr_t addr)
{
    E_ASSERT(device != NULL);
    struct d4e_xil_device *xil_device = container_of(device, struct d4e_xil_device, device);

    return *(uint32_mmptr_t)(xil_device->mmap_ptr + addr);
}

static uint64_t xil_reg_read64(struct d4e_device *device, d4e_addr_t addr)
{
    E_ASSERT(device != NULL);
    struct d4e_xil_device *xil_device = container_of(device, struct d4e_xil_device, device);

    return *(uint64_mmptr_t)(xil_device->mmap_ptr + addr);
}

static void xil_reg_write32(struct d4e_device *device, d4e_addr_t addr, uint32_t value)
{
    E_ASSERT(device != NULL);
    struct d4e_xil_device *xil_device = container_of(device, struct d4e_xil_device, device);

    *(uint32_mmptr_t)(xil_device->mmap_ptr + addr) = value;
}

static void xil_reg_write64(struct d4e_device *device, d4e_addr_t addr, uint64_t value)
{
    E_ASSERT(device != NULL);
    struct d4e_xil_device *xil_device = container_of(device, struct d4e_xil_device, device);

    *(uint64_mmptr_t)(xil_device->mmap_ptr + addr) = value;
}

static int xil_close(struct d4e_device *device)
{
    E_ASSERT(device != NULL);
    struct d4e_xil_device *xil_device = container_of(device, struct d4e_xil_device, device);

    munmap((void *)xil_device->mmap_ptr, xil_device->mmap_size);
    close(xil_device->fd_user);
    close(xil_device->fd_c2h);
    close(xil_device->fd_h2c);
    pthread_mutex_destroy(&xil_device->mtx);

    return 0;
}

int d4e_xil_device_open(
    struct d4e_xil_device *xil_device,
    const char *path_xdma_base,
    int h2c_channel,
    int c2h_channel,
    uint64_t mmap_sz)
{
    E_ASSERT(xil_device != NULL);
    E_ASSERT(path_xdma_base != NULL);

    /** result */
    int r = 0;

    /** path buffer */
    char path_buffer[PATH_MAX];

    memset(xil_device, 0, sizeof(struct d4e_xil_device));

    xil_device->device.interrupt_open = &xil_interrupt_open;
    xil_device->device.interrupt_close = &xil_interrupt_close;
    xil_device->device.interrupt_ack = &xil_interrupt_ack;
    xil_device->device.interrupt_wait = &xil_interrupt_wait;
    xil_device->device.dma_h2d = &xil_dma_h2d;
    xil_device->device.dma_d2h = &xil_dma_d2h;
    xil_device->device.reg_read32 = &xil_reg_read32;
    xil_device->device.reg_read64 = &xil_reg_read64;
    xil_device->device.reg_write32 = &xil_reg_write32;
    xil_device->device.reg_write64 = &xil_reg_write64;
    xil_device->device.close = &xil_close;

    strcpy(xil_device->path_xdma_base, path_xdma_base);
    xil_device->mmap_size = mmap_sz;

    r = pthread_mutex_init(&xil_device->mtx, NULL);
    E_ERR_IF(r != 0, "pthread_mutex_init", 0, error0);

    sprintf(path_buffer, "%s_h2c_%d", path_xdma_base, h2c_channel);
    xil_device->fd_h2c = open(path_buffer, O_WRONLY);
    E_PERR_IF(xil_device->fd_h2c == -1, "open-xdma_h2c", 0, error1);

    sprintf(path_buffer, "%s_c2h_%d", path_xdma_base, c2h_channel);
    xil_device->fd_c2h = open(path_buffer, O_RDONLY);
    E_PERR_IF(xil_device->fd_c2h == -1, "open-xdma_c2h", 0, error2);

    sprintf(path_buffer, "%s_user", path_xdma_base);
    xil_device->fd_user = open(path_buffer, O_RDWR | O_SYNC);
    E_PERR_IF(xil_device->fd_user == -1, "open-xdma_user", 0, error3);

    xil_device->mmap_ptr = (byte_mmptr_t)mmap(NULL, mmap_sz, PROT_READ | PROT_WRITE, MAP_SHARED, xil_device->fd_user, 0x0);
    E_PERR_IF(xil_device->mmap_ptr == MAP_FAILED, "mmap", 0, error4);

    return 0;

error5:
    munmap((void *)xil_device->mmap_ptr, xil_device->mmap_size);

error4:
    close(xil_device->fd_user);

error3:
    close(xil_device->fd_c2h);

error2:
    close(xil_device->fd_h2c);

error1:
    pthread_mutex_destroy(&xil_device->mtx);

error0:
    return -1;
}
