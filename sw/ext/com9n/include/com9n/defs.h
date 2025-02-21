#ifndef COM9N_DEFS_H_INCLUDED
#define COM9N_DEFS_H_INCLUDED

#include <stdint.h>
#include <stddef.h>

#define COM9N_ROLE_SEND 0
#define COM9N_ROLE_RECV 1

typedef com9n_result_t;

/* clang-format off */
#define COM9N_RESULT_SUCCESS    ((com9n_result_t)0)
#define COM9N_RESULT_FAILURE    ((com9n_result_t)-1)
#define COM9N_RESULT_STOPPED    ((com9n_result_t)-2)
#define COM9N_RESULT_NOT_READY  ((com9n_result_t)-3)
#define COM9N_RESULT_CAPACITY   ((com9n_result_t)-4)
/* clang-format on */

#endif /* COM9N_DEFS_H_INCLUDED */
