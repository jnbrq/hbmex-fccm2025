#include <sys/mman.h>

#include <d4e/xil.h>
#include <com9n/d4e.h>

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>

#include <error/error.h>
#include <error/perr.h>

// #define DO_PRINT

struct taskman_task
{
    uint64_t type;
    uint64_t args[8];
};

#define BUFFER_SIZE (256 << 20)

#define HBM_BASE_ADDR               (0x0000000400000000ull)
#define XIL_MAP_SZ (4ULL << 20)

#define CMDQ_ADDR_CONTROL           0x108000ull
#define CMDQ_ADDR_DATA              0x100000ull

#define CMDQ_ADDR_GP_H2C_CONTROL    (CMDQ_ADDR_CONTROL + 24)
#define CMDQ_ADDR_GP_H2C_DATA       (CMDQ_ADDR_DATA + 256)

#define CMDQ_ADDR_GP_C2H_CONTROL    (CMDQ_ADDR_CONTROL + 36)
#define CMDQ_ADDR_GP_C2H_DATA       (CMDQ_ADDR_DATA + 384)

/* clang-format on */

void rand_buffer(uint64_t sz, char *buffer)
{
    for (uint64_t i = 0; i < sz; ++i)
    {
        buffer[i] = (rand() % 256) - 128;
    }
}

/// @brief Compare two buffers.
/// @return 0 if the same, -1 if different
int comp_buffer(uint64_t sz, char *buffer1, char *buffer2)
{
    for (uint64_t i = 0; i < sz; ++i)
    {
        if (buffer1[i] != buffer2[i])
        {
            printf("mismatch at idx = %llu\n", (unsigned long long)i);
            return -1;
        }
    }
    return 0;
}

void catch (int signo)
{
    printf("catch received signal %d\n", signo);
}

int main()
{
    /* Create the D4E client */
    struct d4e_xil_device xil_device;
    E_ERR_IF_DIE(d4e_xil_device_open(&xil_device, "/dev/xdma0", 0, 0, XIL_MAP_SZ) < 0, "d4e_xil_device_open");
    struct d4e_device *device = &xil_device.device;

    /* create the general purpose command queue for tasks */
    struct com9n_d4e cmdq_gp_h2c;
    {
        struct com9n_d4e_config cfg = {
            .addr_data = 0x00100100,
            .addr_control = 0x00108018,
            .capacity = 4,
            .size_msg = sizeof(struct taskman_task),
            .interrupt = 2};

        com9n_d4e_create(&cmdq_gp_h2c, &cfg, &xil_device.device, COM9N_ROLE_SEND, u_mem_malloc_allocator);
    }

    char *buffer1 = malloc(BUFFER_SIZE);
    char *buffer2 = malloc(BUFFER_SIZE);

    rand_buffer(BUFFER_SIZE, buffer1);
    d4e_dma_h2d(device, HBM_BASE_ADDR, buffer1, BUFFER_SIZE);

    struct taskman_task task;

    {
        task.type = 3;
        task.args[0] = 0 /* base without using any TLB */;
        task.args[1] = BUFFER_SIZE;
        task.args[2] = BUFFER_SIZE;
        u_vector_push(&cmdq_gp_h2c.messages, &task);
        com9n_d4e_ssend(&cmdq_gp_h2c);
    }

    d4e_dma_d2h(device, buffer2, HBM_BASE_ADDR + BUFFER_SIZE, BUFFER_SIZE);

    comp_buffer(BUFFER_SIZE, buffer1, buffer2);

    com9n_d4e_destroy(&cmdq_gp_h2c);
    d4e_close(device);

    return EXIT_SUCCESS;
}
