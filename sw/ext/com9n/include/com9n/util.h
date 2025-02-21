#ifndef COM9N_UTIL_H_INCLUDED
#define COM9N_UTIL_H_INCLUDED

#include "defs.h"

#ifdef __cplusplus
extern "C"
{
#endif

com9n_result_t com9n_util_efd_wait(int efd);
com9n_result_t com9n_util_efd_wait2(int efd, int efd_stop);
com9n_result_t com9n_util_efd_signal(int efd);

#ifdef __cplusplus
}
#endif

#endif /* COM9N_UTIL_H_INCLUDED */
