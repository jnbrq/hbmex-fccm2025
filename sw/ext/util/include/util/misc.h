#ifndef UTIL_MISC_H_INCLUDED
#define UTIL_MISC_H_INCLUDED

#include <stddef.h>

#ifndef offsetof

/**
 * @brief Finds the offset of a member in its container type.
 * @param TYPE the container type.
 * @param MEMBER the member identifier.
 */
#define offsetof(TYPE, MEMBER) ((size_t) & ((TYPE *)0)->MEMBER)

#endif

#ifndef container_of

/**
 * @brief Cast a member of a structure out to the containing structure.
 * @param ptr the pointer to the member.
 * @param type the type of the container struct this is embedded in.
 * @param member the name of the member within the struct.
 *
 */
#define container_of(ptr, type, member) \
    (type *)((char *)(ptr)-offsetof(type, member))

#endif

#ifndef memfn
/**
 * @brief Calls a member function.
 * @param ptr the pointer to the object.
 * @param ptr the identifier of the member function.
 */
#define memfn(ptr, func, ...) (((ptr)->func)((ptr)__VA_OPT__(, ) __VA_ARGS__))
#endif

#ifndef ALWAYS_INLINE

/// @brief Marks the function to be always inline.
#define ALWAYS_INLINE inline __attribute__((always_inline))

#endif

#ifndef MAYBE_UNUSED
#   define MAYBE_UNUSED __attribute__((unused))
#endif

#endif /* UTIL_MISC_H_INCLUDED */
