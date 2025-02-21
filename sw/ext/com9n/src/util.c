#include <unistd.h>
#include <sys/eventfd.h>
#include <sys/poll.h>

#include <com9n/util.h>
#include <error/error.h>
#include <error/perr.h>

com9n_result_t com9n_util_efd_wait(int efd)
{
    uint64_t buffer = 0;

    {
        ssize_t result = read(efd, &buffer, sizeof(uint64_t));

        E_PERR_IF(result == -1, "read-eventfd", 0, failure);
        E_ERR_IF(result != sizeof(uint64_t), "read-eventfd", 0, failure);
    }

    return COM9N_RESULT_SUCCESS;

failure:
    return COM9N_RESULT_FAILURE;
}

com9n_result_t com9n_util_efd_wait2(int efd, int efd_stop)
{
    com9n_result_t result = COM9N_RESULT_SUCCESS;

    struct pollfd pollfds[2];

    pollfds[0] = (struct pollfd){
        .fd = efd_stop,
        .events = POLLIN};

    pollfds[1] = (struct pollfd){
        .fd = efd,
        .events = POLLIN};

    int nready = poll(pollfds, 2, -1);
    E_PERR_IF(nready == -1, "poll", result = COM9N_RESULT_FAILURE, end);
    E_PERR_IF(
        pollfds[0].events & POLLERR || pollfds[1].events & POLLERR,
        "poll-pollerr",
        result = COM9N_RESULT_FAILURE,
        end);

    if (pollfds[1].events & POLLIN)
    {
        result = com9n_util_efd_wait(pollfds[1].fd);
        goto end;
    }

    if (pollfds[0].events & POLLIN)
    {
        result = com9n_util_efd_wait(pollfds[0].fd);

        if (result == COM9N_RESULT_SUCCESS)
            result = COM9N_RESULT_STOPPED;

        goto end;
    }

end:
    return result;
}

com9n_result_t com9n_util_efd_signal(int efd)
{
    uint64_t buffer = 1;

    {
        ssize_t result = write(efd, &buffer, sizeof(uint64_t));

        E_PERR_IF(result == -1, "write-eventfd", 0, failure);
        E_ERR_IF(result != sizeof(uint64_t), "write-eventfd", 0, failure);
    }

    return COM9N_RESULT_SUCCESS;

failure:
    return COM9N_RESULT_FAILURE;
}
