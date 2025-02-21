#include <sys/eventfd.h>
#include <unistd.h>

#include <com9n/efd.h>
#include <com9n/util.h>
#include <error/assert.h>
#include <error/error.h>
#include <error/perr.h>

com9n_result_t com9n_efd_create(struct com9n_efd *efd, size_t msg_size, struct u_mem_allocator *allocator)
{
    E_ASSERT(efd != NULL);

    efd->efd_req = eventfd(0, EFD_CLOEXEC);
    E_PERR_IF(efd->efd_req < 0, "eventfd", 0, error0);

    efd->efd_reqdone = eventfd(0, EFD_CLOEXEC);
    E_PERR_IF(efd->efd_reqdone < 0, "eventfd", 0, error1);

    u_vector_create(&efd->messages, allocator, msg_size);
    // TODO error check for u_vector_create
    // E_PERR_IF(<error_cond>, "eventfd", 0, error2);

    return COM9N_RESULT_SUCCESS;

error3:
    u_vector_destroy(&efd->messages);

error2:
    close(efd->efd_reqdone);

error1:
    close(efd->efd_req);

error0:
    return COM9N_RESULT_FAILURE;
}

void com9n_efd_destroy(struct com9n_efd *efd)
{
    u_vector_destroy(&efd->messages);
    close(efd->efd_reqdone);
    close(efd->efd_req);
}

com9n_result_t com9n_efd_sreq(struct com9n_efd *efd)
{
    return com9n_util_efd_signal(efd->efd_req);
}

com9n_result_t com9n_efd_swait(struct com9n_efd *efd)
{
    return com9n_util_efd_wait(efd->efd_reqdone);
}

com9n_result_t com9n_efd_swait2(struct com9n_efd *efd, int efd_stop)
{
    return com9n_util_efd_wait2(efd->efd_reqdone, efd_stop);
}

com9n_result_t com9n_efd_rreqdone(struct com9n_efd *efd)
{
    return com9n_util_efd_signal(efd->efd_reqdone);   
}
