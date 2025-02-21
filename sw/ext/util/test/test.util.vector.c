#include <util/mem.h>
#include <util/vector.h>
#include <stdio.h>

int main()
{
    struct u_vector vector;
    u_vector_create(&vector, u_mem_mmap_allocator, sizeof(uint64_t));

    uint64_t num;

    for (uint64_t i = 0; i < 4096; ++i) {
        u_vector_push(&vector, &i);
    }

    U_VECTOR_ITERATE(uint64_t, p, vector)
    {
        printf("%lu\n", *p);
    }

    u_vector_destroy(&vector);

    return 0;
}
