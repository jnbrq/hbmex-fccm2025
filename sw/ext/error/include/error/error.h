#ifndef ERROR_ERROR_H_INCLUDED
#define ERROR_ERROR_H_INCLUDED

#include "common.h"

/// @brief Used for checking the error condition.
/// @note `do { ... } while(0)` trick to avoid interfering with `else`.
/// @param expr error if `expr` is true.
/// @param msg message to be printed.
/// @param errexpr expression to be evaluated when an error happens.
///                pass 0 if none.
/// @param label to be jumped in case of an error.
#define E_ERR_IF(expr, msg, errexpr, label)                        \
    do                                                             \
    {                                                              \
        if (expr)                                                  \
        {                                                          \
            e_print(                                               \
                "[ ERROR  ] " msg                                  \
                " (from " __FILE__ ":" E_STRINGIZE(__LINE__) ")"); \
            (void)(errexpr);                                       \
            goto label;                                            \
        }                                                          \
    } while (0)

/// @brief Used for checking the error condition.
///
///        Simply force quits the application.
/// @param expr error if `expr` is true.
/// @param msg message to be printed.
#define E_ERR_IF_DIE(expr, msg)                                    \
    do                                                             \
    {                                                              \
        if (expr)                                                  \
        {                                                          \
            e_print(                                               \
                "[ ERROR  ] " msg                                  \
                " (from " __FILE__ ":" E_STRINGIZE(__LINE__) ")"); \
            e_die();                                               \
        }                                                          \
    } while (0)

#endif /* ERROR_ERROR_H_INCLUDED */
