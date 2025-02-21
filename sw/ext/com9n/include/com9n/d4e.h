#ifndef COM9N_D4E_H_INCLUDED
#define COM9N_D4E_H_INCLUDED

#include "defs.h"

#include <util/vector.h>
#include <d4e/interface.h>

#ifdef __cplusplus
extern "C"
{
#endif

struct com9n_d4e_config
{
    /// @brief Address of the queue data (for DMA transfers).
    uint64_t addr_data;

    /// @brief Address of the control block.
    uint64_t addr_control;

    /// @brief Number of total messages that can be hosted by the queue.
    uint64_t capacity;

    /// @brief Message size.
    uint64_t size_msg;

    /**
     * @brief Interrupt number for request.
     *
     * @note Card queue: interrupt for request done.
     * @note Host queue: interrupt for request.
     *
     */
    uint64_t interrupt;

    /// @brief 1 if 64-bit register reads/writes should be used.
    int use64bit;
};

struct com9n_d4e
{
    /// @brief Device.
    struct d4e_device *device;

    /// @brief Interrupt file descriptor.
    int fd_interrupt;

    struct {
        /// @brief Role of the queue. Send or receive.
        int role;
        
        /// @brief Message size.
        uint64_t size_msg;

        /// @brief Number of total messages that can be hosted by the queue.
        uint64_t capacity;
        
        /// @brief 1 if 64-bit register reads/writes should be used.
        int use64bit;
    } cfg;

    struct {
        /// @brief Address of the queue data (for DMA transfers).
        d4e_addr_t data;

        /// @brief Address of the length register.
        d4e_addr_t length;

        /**
         * @brief Address of the communication flag set in case of a request.
         *
         * @note Card queue: set by the host, reset by the card.
         * @note Host queue: set by the card, reset by the host.
         *
         */
        d4e_addr_t req;

        /**
         * @brief Address of the communication flag set in case of a request completion.
         *
         * @note Card queue: set by the card, reset by the host.
         * @note Host queue: set by the host, reset by the card.
         *
         */
        d4e_addr_t reqdone;
    } addr;

    /// @brief Messages.
    struct u_vector messages;

    struct {
        int nb_ongoing;
    } logic;
};

com9n_result_t com9n_d4e_create(
    struct com9n_d4e *cmdq,
    struct com9n_d4e_config const *cfg,
    struct d4e_device *device,
    int role,
    struct u_mem_allocator *allocator);

void com9n_d4e_destroy(struct com9n_d4e *cmdq);

com9n_result_t com9n_d4e_ssend(struct com9n_d4e *cmdq);

/**
 * @brief 
 * 
 * @param cmdq 
 * @return com9n_result_t 0 if success, COM9N_RESULT_CAPACITY if
 * the capacity is not enough to initiate a non-blocking transfer.
 */
com9n_result_t com9n_d4e_ssend_nbinit(struct com9n_d4e *cmdq);

com9n_result_t com9n_d4e_ssend_nbwait(struct com9n_d4e *cmdq);

com9n_result_t com9n_d4e_rrecv(struct com9n_d4e *cmdq);

com9n_result_t com9n_d4e_rwait(struct com9n_d4e *cmdq);

com9n_result_t com9n_d4e_rack(struct com9n_d4e *cmdq);

com9n_result_t com9n_d4e_rdone(struct com9n_d4e *cmdq);

#ifdef __cplusplus
}
#endif

#endif /* COM9N_D4E_H_INCLUDED */
