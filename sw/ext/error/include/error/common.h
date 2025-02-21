#ifndef ERROR_COMMON_H_INCLUDED
#define ERROR_COMMON_H_INCLUDED

#ifdef __cplusplus
extern "C"
{
#endif

#define E_STRINGIZE_DETAIL(x) #x
#define E_STRINGIZE(x) E_STRINGIZE_DETAIL(x)

/// @brief Error message printing.
/// @param msg Message.
void e_print(const char *msg);

/// @brief Called on die.
void e_die();

#ifdef __cplusplus
}
#endif

#endif /* ERROR_COMMON_H_INCLUDED */
