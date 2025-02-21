#define _LARGEFILE64_SOURCE
#include <unistd.h>
#include <poll.h>

#include <error/error.h>
#include <error/perr.h>
#include <com9n/util.h>
#include <d4e/interface.h>

int d4e_interrupt_open(struct d4e_device *device, uint64_t interrupt_id)
{
    return device->interrupt_open(device, interrupt_id);
}

int d4e_interrupt_close(struct d4e_device *device, int fd)
{
    return device->interrupt_close(device, fd);
}

int d4e_interrupt_ack(struct d4e_device *device, int fd)
{
    return device->interrupt_ack(device, fd);
}

int d4e_interrupt_wait(struct d4e_device *device, int fd)
{
    return device->interrupt_wait(device, fd);
}

int d4e_interrupt_wait2(struct d4e_device *device, int fd, int efd_stop)
{
    int result = 0;

    struct pollfd pollfds[2];

    pollfds[0] = (struct pollfd){
        .fd = efd_stop,
        .events = POLLIN};

    pollfds[1] = (struct pollfd){
        .fd = fd,
        .events = POLLIN};

    int nready = poll(pollfds, 2, -1);

    E_PERR_IF(nready == -1, "poll", result = -1, end);
    E_PERR_IF(
        pollfds[0].events & POLLERR || pollfds[1].events & POLLERR,
        "poll-pollerr",
        result = D4E_ERROR,
        end);

    if (pollfds[1].events & POLLIN)
    {
        result = d4e_interrupt_ack(device, fd);
        goto end;
    }

    if (pollfds[0].events & POLLIN)
    {
        if (com9n_util_efd_wait(efd_stop) < 0)
        {
            result = D4E_ERROR;
            goto end;
        }

        result = D4E_STOPPED;
        goto end;
    }

end:
    return result;
}

int d4e_dma_d2h(struct d4e_device *device, void *dest, d4e_addr_t src, size_t size)
{
    return device->dma_d2h(device, dest, src, size);
}

int d4e_dma_h2d(struct d4e_device *device, d4e_addr_t dest, void const *src, size_t size)
{
    return device->dma_h2d(device, dest, src, size);
}

uint32_t d4e_reg_read32(struct d4e_device *device, d4e_addr_t addr)
{
    return device->reg_read32(device, addr);
}

uint64_t d4e_reg_read64(struct d4e_device *device, d4e_addr_t addr)
{
    return device->reg_read64(device, addr);
}

void d4e_reg_write32(struct d4e_device *device, d4e_addr_t addr, uint32_t value)
{
    device->reg_write32(device, addr, value);
}

void d4e_reg_write64(struct d4e_device *device, d4e_addr_t addr, uint64_t value)
{
    device->reg_write64(device, addr, value);
}

int d4e_close(struct d4e_device *device)
{
    return device->close(device);
}
