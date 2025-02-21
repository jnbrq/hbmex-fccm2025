#ifndef ERROR_PERR_H_INCLUDED
#define ERROR_PERR_H_INCLUDED

#include "common.h"
#include <stdio.h>

/// @brief Used for checking the error condition, extra information
///        is printed with `perr`.
/// @param expr error if `expr` is true.
/// @param msg message to be printed as part of `perror` call.
/// @param errexpr expression to be evaluated when an error happens.
///                pass 0 if none.
/// @param label to be jumped in case of an error.
#define E_PERR_IF(expr, msg, errexpr, label)                       \
    do                                                             \
    {                                                              \
        if (expr)                                                  \
        {                                                          \
            perror(                                                \
                "[ PERR   ] " msg                                  \
                " (from " __FILE__ ":" E_STRINGIZE(__LINE__) ")"); \
            (void)(errexpr);                                       \
            goto label;                                            \
        }                                                          \
    } while (0)

/// @brief Used for checking the error condition, extra information
///        is printed with `perror`.
///
///        Simply force quits the application.
/// @param expr error if `expr` is true.
/// @param msg message to be printed as part of `perr` call.
#define E_PERR_IF_DIE(expr, msg)                                   \
    do                                                             \
    {                                                              \
        if (expr)                                                  \
        {                                                          \
            perror(                                                \
                "[ PERR   ] " msg                                  \
                " (from " __FILE__ ":" E_STRINGIZE(__LINE__) ")"); \
            e_die();                                               \
        }                                                          \
    } while (0)

#endif /* ERROR_PERR_H_INCLUDED */
