#include <d4e/xil.h>
#include <error/perr.h>
#include <error/error.h>

#include <unistd.h>
#include <poll.h>

int main()
{
    struct d4e_xil_device xil_device;
    E_ERR_IF_DIE(
        d4e_xil_device_open(&xil_device, "/dev/xdma0", 0, 0, 4 << 20) < 0,
        "d4e_xil_device_open");
    
    struct pollfd pollfds[16];

    for (int i = 0; i < 16; ++i)
    {
        pollfds[i].fd = d4e_interrupt_open(&xil_device.device, i);
        pollfds[i].events = POLLIN;
    }

    while (1)
    {
        int nready = poll(pollfds, 16, -1);
        E_PERR_IF_DIE(nready == -1, "poll");

        for (int i = 0; i < 16; ++i)
        {
            E_ERR_IF_DIE(pollfds[i].revents & POLLERR, "poll-fd");

            if (pollfds[i].revents & POLLIN)
                E_ERR_IF_DIE(d4e_interrupt_ack(&xil_device.device, pollfds[i].fd) < 0, "d4e_interrupt_ack");
        }
    }

    return 0;
}
