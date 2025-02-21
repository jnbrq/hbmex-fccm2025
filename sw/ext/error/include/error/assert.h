#ifndef ERROR_ASSERT_H_INCLUDED
#define ERROR_ASSERT_H_INCLUDED

#include "common.h"

#ifndef E_ASSERT_OFF

/// @brief Asserts `expr`.
#define E_ASSERT(expr)                                               \
    do                                                               \
    {                                                                \
        if (!(expr))                                                 \
        {                                                            \
            e_print(                                                 \
                "[ ASSERT ] " #expr                                  \
                " (from " __FILE__ ":" E_STRINGIZE(__LINE__) ")\n"); \
            e_die();                                                 \
        }                                                            \
    } while (0)

#else

#define E_ASSERT(expr)

#endif

#endif /* ERROR_ASSERT_H_INCLUDED */
