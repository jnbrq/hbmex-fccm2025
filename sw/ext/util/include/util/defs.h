#ifndef UTIL_DEFS_H_INCLUDED
#define UTIL_DEFS_H_INCLUDED

typedef int u_result_t;

#define U_RESULT(I) ((u_result_t) (I))

#define U_SUCCESS       U_RESULT(0)
#define U_FAILURE       U_RESULT(-1)
#define U_EALLOC        U_RESULT(-10)
#define U_EINVALID      U_RESULT(-11)
#define U_ECAPACITY     U_RESULT(-12)
#define U_EEMPTY        U_RESULT(-13)

#endif /* UTIL_DEFS_H_INCLUDED */

