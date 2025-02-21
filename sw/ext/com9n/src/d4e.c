#include <com9n/d4e.h>

#include <error/assert.h>
#include <error/error.h>
#include <string.h>

#define MIN(x, y) (((x) < (y)) ? (x) : (y))
#define MAX(x, y) (((x) > (y)) ? (x) : (y))

com9n_result_t com9n_d4e_create(
    struct com9n_d4e *cmdq,
    struct com9n_d4e_config const *cfg,
    struct d4e_device *device,
    int role,
    struct u_mem_allocator *allocator)
{
    E_ASSERT(cmdq != NULL);
    E_ASSERT(cfg != NULL);
    E_ASSERT(device != NULL);
    E_ASSERT(allocator != NULL);

    cmdq->fd_interrupt = d4e_interrupt_open(device, cfg->interrupt);
    if (cmdq->fd_interrupt < 0)
    {
        return COM9N_RESULT_FAILURE;
    }

    cmdq->cfg.role = role;
    cmdq->cfg.size_msg = cfg->size_msg;
    cmdq->cfg.capacity = cfg->capacity;
    cmdq->cfg.use64bit = cfg->use64bit;

    cmdq->addr.data = cfg->addr_data;

    {
        unsigned offset = cfg->use64bit ? 8 : 4;
        cmdq->addr.req = cfg->addr_control + (0 * offset);
        cmdq->addr.reqdone = cfg->addr_control + (1 * offset);
        cmdq->addr.length = cfg->addr_control + (2 * offset);
    }

    cmdq->device = device;

    u_vector_create2(&cmdq->messages, allocator, cfg->size_msg, cfg->capacity);

    cmdq->logic.nb_ongoing = 0;

    return 0;
}

void com9n_d4e_destroy(struct com9n_d4e *cmdq)
{
    E_ASSERT(cmdq != NULL);

    u_vector_destroy(&cmdq->messages);
    d4e_interrupt_close(cmdq->device, cmdq->fd_interrupt);
}

static uint32_t reg_read(struct com9n_d4e *cmdq, d4e_addr_t addr)
{
    if (cmdq->cfg.use64bit)
        return d4e_reg_read64(cmdq->device, addr);
    else
        return d4e_reg_read32(cmdq->device, addr);
}

static void reg_write(struct com9n_d4e *cmdq, d4e_addr_t addr, uint32_t value)
{
    if (cmdq->cfg.use64bit)
        d4e_reg_write64(cmdq->device, addr, value);
    else
        d4e_reg_write32(cmdq->device, addr, value);
}

static com9n_result_t send_partial(struct com9n_d4e *cmdq, void *buffer, size_t offset, size_t length)
{
    size_t size_msg = cmdq->cfg.size_msg;

    reg_write(cmdq, cmdq->addr.reqdone, 0);
    reg_write(cmdq, cmdq->addr.req, 0);

    size_t write_size = length * size_msg;
    if (d4e_dma_h2d(cmdq->device, cmdq->addr.data, buffer + offset * size_msg, write_size) < 0)
        return -1;

    // interrupt the processor
    reg_write(cmdq, cmdq->addr.length, length);
    reg_write(cmdq, cmdq->addr.req, 1);

    // wait for the card response
    // while loop is to ensure that there is no spurious wake-up
    // the driver somehow creates interrupts for no reason (after writes)
    while (!reg_read(cmdq, cmdq->addr.reqdone))
    {
        if (d4e_interrupt_wait(cmdq->device, cmdq->fd_interrupt) < 0)
            return COM9N_RESULT_FAILURE;
    }

    return COM9N_RESULT_SUCCESS;
}

com9n_result_t com9n_d4e_ssend(struct com9n_d4e *cmdq)
{
    E_ASSERT(cmdq != NULL);
    E_ASSERT(cmdq->cfg.role == COM9N_ROLE_SEND);

    size_t length = cmdq->messages.length;
    size_t capacity = cmdq->cfg.capacity;

    if (length == 0)
        return 0;

    // partition the messages vector
    for (
        size_t i = 0, j = length;
        i < length;
        i += capacity, j -= capacity)
    {
        com9n_result_t res = send_partial(cmdq, cmdq->messages.data, i, MIN(capacity, j));

        if (res < 0)
            return res;
    }

    u_vector_clear(&cmdq->messages);

    return COM9N_RESULT_SUCCESS;
}

com9n_result_t com9n_d4e_ssend_nbinit(struct com9n_d4e *cmdq)
{
    E_ASSERT(cmdq != NULL);
    E_ASSERT(cmdq->cfg.role == COM9N_ROLE_SEND);

    size_t length = cmdq->messages.length;
    
    if (length > cmdq->cfg.capacity)
        // cannot start the operation due to limited capacity
        return COM9N_RESULT_CAPACITY;

    cmdq->logic.nb_ongoing = 1;

    reg_write(cmdq, cmdq->addr.reqdone, 0);
    reg_write(cmdq, cmdq->addr.req, 0);
    void *data = (void *)cmdq->messages.data;
    size_t write_size = length * cmdq->cfg.size_msg;

    if (d4e_dma_h2d(cmdq->device, cmdq->addr.data, data, write_size) < 0)
        return COM9N_RESULT_FAILURE;

    // interrupt the processor
    reg_write(cmdq, cmdq->addr.length, length);
    reg_write(cmdq, cmdq->addr.req, 1);

    return COM9N_RESULT_SUCCESS;
}

com9n_result_t com9n_d4e_ssend_nbwait(struct com9n_d4e *cmdq)
{
    E_ASSERT(cmdq != NULL);
    E_ASSERT(cmdq->cfg.role == COM9N_ROLE_SEND);

    E_ASSERT(cmdq->logic.nb_ongoing && "there must be an ongoing non-blocking send");
    cmdq->logic.nb_ongoing = 0;

    while (!reg_read(cmdq, cmdq->addr.reqdone))
    {
        if (d4e_interrupt_wait(cmdq->device, cmdq->fd_interrupt) < 0)
            return COM9N_RESULT_FAILURE;
    }

    return COM9N_RESULT_SUCCESS;
}

com9n_result_t com9n_d4e_rrecv(struct com9n_d4e *cmdq)
{
    E_ASSERT(cmdq != NULL);
    E_ASSERT(cmdq->cfg.role == COM9N_ROLE_RECV);

    if (!reg_read(cmdq, cmdq->addr.req))
        return COM9N_RESULT_NOT_READY;

    size_t length = reg_read(cmdq, cmdq->addr.length);
    size_t size = length * cmdq->cfg.size_msg;

    u_vector_clear(&cmdq->messages);
    u_vector_push_n2(&cmdq->messages, length);

    if (d4e_dma_d2h(cmdq->device, cmdq->messages.data, cmdq->addr.data, size) < 0)
        return COM9N_RESULT_FAILURE;

    reg_write(cmdq, cmdq->addr.req, 0);

    return COM9N_RESULT_SUCCESS;
}

com9n_result_t com9n_d4e_rwait(struct com9n_d4e *cmdq)
{
    E_ASSERT(cmdq != NULL);
    E_ASSERT(cmdq->cfg.role == COM9N_ROLE_RECV);

    if (d4e_interrupt_wait(cmdq->device, cmdq->fd_interrupt) < 0)
        return COM9N_RESULT_FAILURE;

    return COM9N_RESULT_SUCCESS;
}

com9n_result_t com9n_d4e_rack(struct com9n_d4e *cmdq)
{
    E_ASSERT(cmdq != NULL);
    E_ASSERT(cmdq->cfg.role == COM9N_ROLE_RECV);

    if (d4e_interrupt_ack(cmdq->device, cmdq->fd_interrupt))
        return COM9N_RESULT_FAILURE;

    return COM9N_RESULT_SUCCESS;
}

com9n_result_t com9n_d4e_rdone(struct com9n_d4e *cmdq)
{
    E_ASSERT(cmdq != NULL);
    E_ASSERT(cmdq->cfg.role == COM9N_ROLE_RECV);

    reg_write(cmdq, cmdq->addr.reqdone, 1);

    return COM9N_RESULT_SUCCESS;
}
