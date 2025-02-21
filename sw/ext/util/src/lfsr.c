#include <util/lfsr.h>
#include <error/assert.h>
#include <limits.h>

#ifndef E_ASSERT_OFF

static unsigned u_lfsr_count1s(u_lfsr_unsigned_t x)
{
    return __builtin_choose_expr(
        __builtin_types_compatible_p(unsigned int, u_lfsr_unsigned_t),
        __builtin_popcount((unsigned int)x),
        __builtin_choose_expr(
            __builtin_types_compatible_p(unsigned long, u_lfsr_unsigned_t),
            __builtin_popcountl((unsigned long)x),
            __builtin_choose_expr(
                __builtin_types_compatible_p(unsigned long long, u_lfsr_unsigned_t),
                __builtin_popcountll((unsigned long long)x),
                (void)0)));
}

#endif

static unsigned u_lfsr_xor_reduce(u_lfsr_unsigned_t x)
{
    return __builtin_choose_expr(
        __builtin_types_compatible_p(unsigned int, u_lfsr_unsigned_t),
        __builtin_parity((unsigned int)x),
        __builtin_choose_expr(
            __builtin_types_compatible_p(unsigned long, u_lfsr_unsigned_t),
            __builtin_parityl((unsigned long)x),
            __builtin_choose_expr(
                __builtin_types_compatible_p(unsigned long long, u_lfsr_unsigned_t),
                __builtin_parityll((unsigned long long)x),
                (void)0)));
}

static u_lfsr_unsigned_t u_lfsr_feedbacks[] = {
    U_LFSR_UNSIGNED(0x9),
    U_LFSR_UNSIGNED(0x12),
    U_LFSR_UNSIGNED(0x21),
    U_LFSR_UNSIGNED(0x41),
    U_LFSR_UNSIGNED(0x8E),
    U_LFSR_UNSIGNED(0x108),
    U_LFSR_UNSIGNED(0x204),
    U_LFSR_UNSIGNED(0x402),
    U_LFSR_UNSIGNED(0x829),
    U_LFSR_UNSIGNED(0x100D),
    U_LFSR_UNSIGNED(0x2015),
    U_LFSR_UNSIGNED(0x4001),
    U_LFSR_UNSIGNED(0x8016),
    U_LFSR_UNSIGNED(0x10004),
    U_LFSR_UNSIGNED(0x20013),
    U_LFSR_UNSIGNED(0x40013),
    U_LFSR_UNSIGNED(0x80004),
    U_LFSR_UNSIGNED(0x100002),
    U_LFSR_UNSIGNED(0x200001),
    U_LFSR_UNSIGNED(0x400010),
    U_LFSR_UNSIGNED(0x80000D),
    U_LFSR_UNSIGNED(0x1000004),
    U_LFSR_UNSIGNED(0x2000023),
    U_LFSR_UNSIGNED(0x4000013),
    U_LFSR_UNSIGNED(0x8000004),
    U_LFSR_UNSIGNED(0x10000002),
    U_LFSR_UNSIGNED(0x20000029),
    U_LFSR_UNSIGNED(0x40000004),
    U_LFSR_UNSIGNED(0x80000057),
    U_LFSR_UNSIGNED(0x100000029),
    U_LFSR_UNSIGNED(0x200000073),
    U_LFSR_UNSIGNED(0x400000002),
    U_LFSR_UNSIGNED(0x80000003B),
    U_LFSR_UNSIGNED(0x100000001F),
    U_LFSR_UNSIGNED(0x2000000031),
    U_LFSR_UNSIGNED(0x4000000008),
    U_LFSR_UNSIGNED(0x800000001C),
    U_LFSR_UNSIGNED(0x10000000004),
    U_LFSR_UNSIGNED(0x2000000001F),
    U_LFSR_UNSIGNED(0x4000000002C),
    U_LFSR_UNSIGNED(0x80000000032),
    U_LFSR_UNSIGNED(0x10000000000D),
    U_LFSR_UNSIGNED(0x200000000097),
    U_LFSR_UNSIGNED(0x400000000010),
    U_LFSR_UNSIGNED(0x80000000005B),
    U_LFSR_UNSIGNED(0x1000000000038),
    U_LFSR_UNSIGNED(0x200000000000E),
    U_LFSR_UNSIGNED(0x4000000000025),
    U_LFSR_UNSIGNED(0x8000000000004),
    U_LFSR_UNSIGNED(0x10000000000023),
    U_LFSR_UNSIGNED(0x2000000000003E),
    U_LFSR_UNSIGNED(0x40000000000023),
    U_LFSR_UNSIGNED(0x8000000000004A),
    U_LFSR_UNSIGNED(0x100000000000016),
    U_LFSR_UNSIGNED(0x200000000000031),
    U_LFSR_UNSIGNED(0x40000000000003D),
    U_LFSR_UNSIGNED(0x800000000000001),
    U_LFSR_UNSIGNED(0x1000000000000013),
    U_LFSR_UNSIGNED(0x2000000000000034),
    U_LFSR_UNSIGNED(0x4000000000000001),
    U_LFSR_UNSIGNED(0x800000000000000D)};

void u_lfsr_fibonacci_init(struct u_lfsr_fibonacci *lfsr_fibonacci, unsigned nbits, u_lfsr_unsigned_t state, int xnor)
{
    E_ASSERT(nbits >= 4 && nbits <= 64);
    u_lfsr_fibonacci_init2(lfsr_fibonacci, nbits, state, xnor, u_lfsr_feedbacks[nbits - 4]);
}

void u_lfsr_fibonacci_init2(struct u_lfsr_fibonacci *lfsr_fibonacci, unsigned nbits, u_lfsr_unsigned_t state, int xnor, u_lfsr_unsigned_t feedback)
{
    E_ASSERT(nbits >= 4 && nbits <= (sizeof(u_lfsr_unsigned_t) * CHAR_BIT));
    lfsr_fibonacci->_.mask = (U_LFSR_UNSIGNED(1) << nbits) - U_LFSR_UNSIGNED(1);

    E_ASSERT((!xnor && (state > U_LFSR_UNSIGNED(0))) || (xnor && (state + U_LFSR_UNSIGNED(1) >= U_LFSR_UNSIGNED(0))));
    lfsr_fibonacci->_.state = state;
    lfsr_fibonacci->_.xnor = xnor;

    E_ASSERT((!xnor || (xnor && (u_lfsr_count1s(feedback) % 2 == 0))) && "feedback must have an even number of 1s for xnor");
    lfsr_fibonacci->_.feedback = feedback;
}

u_lfsr_unsigned_t u_lfsr_fibonacci_next(struct u_lfsr_fibonacci *lfsr_fibonacci)
{
    u_lfsr_unsigned_t feedback = lfsr_fibonacci->_.feedback;
    u_lfsr_unsigned_t mask = lfsr_fibonacci->_.mask;
    u_lfsr_unsigned_t next = lfsr_fibonacci->_.state;

    if (lfsr_fibonacci->_.xnor)
        next = ((next << 1u) | !u_lfsr_xor_reduce(next & feedback)) & mask;
    else
        next = ((next << 1u) | u_lfsr_xor_reduce(next & feedback)) & mask;

    lfsr_fibonacci->_.state = next;
    return next;
}
