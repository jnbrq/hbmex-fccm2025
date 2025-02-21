#ifndef COM9N_EFD_H_INCLUDED
#define COM9N_EFD_H_INCLUDED

#include "defs.h"

#include <util/mem.h>
#include <util/vector.h>

#include <sys/eventfd.h>
#include <unistd.h>

#ifdef __cplusplus
extern "C"
{
#endif

struct com9n_efd
{
    /**
     * @brief Eventfd for requests.
     * @note Do not modify.
     * 
     */
    int efd_req;

    /**
     * @brief Eventfd for responses (i.e., the request is handled).
     * @note Do not modify.
     * 
     */
    int efd_reqdone;

    /**
     * @brief Messages to be read by the receiver and written by the sender.
     * @note Safe to use `u_vector_XXX` functions on this object.
     * 
     */
    struct u_vector messages;
};

/**
 * @brief Creates an eventfd-based communication channel.
 * @note Two actors act upon the created channel object: sender and receiver.
 * The sender is supposed to call functions that start with `s` and the receiver should call
 * the functions that start with `r`.
 *
 * @param channel
 * @param msg_size
 * @param allocator
 * @return com9n_result_t
 */
com9n_result_t com9n_efd_create(struct com9n_efd *channel, size_t msg_size, struct u_mem_allocator *allocator);

/**
 * @brief Destroys the channel.
 *
 * @param channel
 */
void com9n_efd_destroy(struct com9n_efd *channel);

/**
 * @brief Issues a request.
 * @note Supposed to be called by the sender.
 *
 * @param efd
 * @return com9n_result_t
 */
com9n_result_t com9n_efd_sreq(struct com9n_efd *efd);

/**
 * @brief Wait until the request completes.
 * @note Supposed to be called by the sender.
 * 
 * @param efd 
 * @return com9n_result_t 
 */
com9n_result_t com9n_efd_swait(struct com9n_efd *efd);


/**
 * @brief Wait until the request completes. Interruptable by efd_stop.
 * @note Supposed to be called by the sender.
 * 
 * @param efd 
 * @param efd_stop 
 * @return com9n_result_t 
 */
com9n_result_t com9n_efd_swait2(struct com9n_efd *efd, int efd_stop);

/**
 * @brief Notify the sender that the request handling is complete.
 * @note Supposed to be called by the receiver.
 * 
 * @param efd 
 * @return com9n_result_t 
 */
com9n_result_t com9n_efd_rreqdone(struct com9n_efd *efd);

#ifdef __cplusplus
}
#endif

#endif /* COM9N_EFD_H_INCLUDED */
