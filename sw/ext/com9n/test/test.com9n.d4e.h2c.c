#include <d4e/xil.h>
#include <com9n/d4e.h>

#include <stdio.h>
#include <stdlib.h>

/* clang-format off */
#define MAP_SZ (4ULL << 20)

#define CMDQ_ADDR_CONTROL           0x108000ull
#define CMDQ_ADDR_DATA              0x100000ull

#define CMDQ_ADDR_SVM_H2C_CONTROL   (CMDQ_ADDR_CONTROL + 0)
#define CMDQ_ADDR_SVM_H2C_DATA      (CMDQ_ADDR_DATA + 0)

#define CMDQ_ADDR_SVM_C2H_CONTROL   (CMDQ_ADDR_CONTROL + 12)
#define CMDQ_ADDR_SVM_C2H_DATA      (CMDQ_ADDR_DATA + 128)

#define CMDQ_ADDR_GP_H2C_CONTROL    (CMDQ_ADDR_CONTROL + 24)
#define CMDQ_ADDR_GP_H2C_DATA       (CMDQ_ADDR_DATA + 256)

#define CMDQ_ADDR_GP_C2H_CONTROL    (CMDQ_ADDR_CONTROL + 36)
#define CMDQ_ADDR_GP_C2H_DATA       (CMDQ_ADDR_DATA + 384)

/* clang-format on */

int main()
{
    struct d4e_xil_device xil_device;
    if (d4e_xil_device_open(&xil_device, "/dev/xdma0", 0, 0, MAP_SZ) < 0)
        return EXIT_FAILURE;
    
    struct com9n_d4e cmdq;
    struct com9n_d4e_config cfg = {
        .addr_data = CMDQ_ADDR_GP_H2C_DATA,
        .addr_control = CMDQ_ADDR_GP_H2C_CONTROL,
        .capacity = 16,
        .size_msg = sizeof(uint32_t),
        .interrupt = 2
    };

    com9n_d4e_create(&cmdq, &cfg, &xil_device.device, COM9N_ROLE_SEND, u_mem_malloc_allocator);

    u_vector_clear(&cmdq.messages);

    int x;

    x = 8;
    u_vector_push(&cmdq.messages, &x);

    x = 14;
    u_vector_push(&cmdq.messages, &x);

    x = 89;
    u_vector_push(&cmdq.messages, &x);

    com9n_d4e_ssend(&cmdq);

    com9n_d4e_destroy(&cmdq);
    d4e_close(&xil_device.device);

    return 0;
}
