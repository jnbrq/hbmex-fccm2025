#include <sys/mman.h>

#include <d4e/xil.h>
#include <com9n/d4e.h>

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>

#include <error/error.h>
#include <error/perr.h>

struct taskman_task
{
    uint64_t type;
    uint64_t args[8];
};

#define XIL_MAP_SZ (4ULL << 20)

#define CMDQ_ADDR_CONTROL           0x108000ull
#define CMDQ_ADDR_DATA              0x100000ull

#define CMDQ_ADDR_GP_H2C_CONTROL    (CMDQ_ADDR_CONTROL + 24)
#define CMDQ_ADDR_GP_H2C_DATA       (CMDQ_ADDR_DATA + 256)

#define CMDQ_ADDR_GP_C2H_CONTROL    (CMDQ_ADDR_CONTROL + 36)
#define CMDQ_ADDR_GP_C2H_DATA       (CMDQ_ADDR_DATA + 384)

/* clang-format on */

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

    struct taskman_task task = {0};

    task.type = 2;

    task.args[0] = 487;
    u_vector_push(&cmdq_gp_h2c.messages, &task);

    task.args[0] = 47;
    u_vector_push(&cmdq_gp_h2c.messages, &task);

    task.args[0] = 7;
    u_vector_push(&cmdq_gp_h2c.messages, &task);

    task.args[0] = 48;
    u_vector_push(&cmdq_gp_h2c.messages, &task);

    task.args[0] = 87;
    u_vector_push(&cmdq_gp_h2c.messages, &task);

    task.args[0] = 47487;
    u_vector_push(&cmdq_gp_h2c.messages, &task);

    com9n_d4e_ssend(&cmdq_gp_h2c);

    com9n_d4e_destroy(&cmdq_gp_h2c);
    d4e_close(device);

    return EXIT_SUCCESS;
}
