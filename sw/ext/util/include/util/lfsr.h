#ifndef UTIL_LFSR_H_INCLUDED
#define UTIL_LFSR_H_INCLUDED

#include <stdint.h>

#ifdef __cplusplus
extern "C"
{
#endif

typedef uint64_t u_lfsr_unsigned_t;

#define U_LFSR_UNSIGNED(x) ((u_lfsr_unsigned_t)(x##ull))

struct u_lfsr_fibonacci
{
    struct {
        u_lfsr_unsigned_t mask;
        u_lfsr_unsigned_t state;
        int xnor;
        u_lfsr_unsigned_t feedback;
    } _;
};

void u_lfsr_fibonacci_init(struct u_lfsr_fibonacci *lfsr_fibonacci, unsigned nbits, u_lfsr_unsigned_t state, int xnor);
void u_lfsr_fibonacci_init2(struct u_lfsr_fibonacci *lfsr_fibonacci, unsigned nbits, u_lfsr_unsigned_t state, int xnor, u_lfsr_unsigned_t feedback);
u_lfsr_unsigned_t u_lfsr_fibonacci_next(struct u_lfsr_fibonacci *lfsr_fibonacci);

#ifdef __cplusplus
}
#endif

#endif /* UTIL_LFSR_H_INCLUDED */
