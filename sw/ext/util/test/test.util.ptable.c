#include <util/ptable.h>
#include <time.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

void print_ptable(struct u_ptable *ptable)
{
    u_ptable_elem_t *it;
    u_ptable_elem_t *end;
    size_t step_set, num_ways, step_way;

    int print_second = u_ptable_info(ptable)->row_length > 1;

    u_ptable_iter(ptable, &it, &end, &step_set, &num_ways, &step_way);

    int n = 0;
    while (it != end)
    {
        printf(
            "%04x : %lx , %ld\n",
            n++,
            (unsigned long) it[0],
            print_second ? (unsigned long) it[1] : 0);
        it += step_way;
    }
}

void test1()
{
    printf("%s\n", __func__);

    struct u_ptable_config cfg = {
        .flavor = U_PTABLE_OPENADDRESSING,
        .row_length_bits = 0,
        .num_ways_bits = 0,
        .offset_bits = 0,
        .lookup_bits = 4};
    struct u_ptable ptable;
    u_ptable_create(&ptable, u_mem_malloc_allocator, &cfg);

    u_ptable_elem_t *row;

    // lookup bits:
    //  0 0000  ---> 0
    //  1 0000  ---> 16

    row = u_ptable_new(&ptable, 0 + (1 << 10) * 0);
    *row = U_PTABLE_REGISTERED_MASK | (0 + (1 << 10) * 0);
    printf("row = %p\n", row);

    row = u_ptable_new(&ptable, 16 + (1 << 10) * 1);
    *row = U_PTABLE_REGISTERED_MASK | (16 + (1 << 10) * 1);
    printf("row = %p\n", row);

    row = u_ptable_new(&ptable, 0 + (1 << 10) * 2);
    *row = U_PTABLE_REGISTERED_MASK | (0 + (1 << 10) * 2);
    printf("row = %p\n", row);

    row = u_ptable_new(&ptable, 16 + (1 << 10) * 3);
    *row = U_PTABLE_REGISTERED_MASK | (16 + (1 << 10) * 3);
    printf("row = %p\n", row);

    row = u_ptable_new(&ptable, 0 + (1 << 10) * 4);
    *row = U_PTABLE_REGISTERED_MASK | (0 + (1 << 10) * 4);
    printf("row = %p\n", row);

    *row |= ((u_ptable_elem_t)5) << U_PTABLE_ADDR_BITS;
    u_ptable_elem_t *row2 = u_ptable_get(&ptable, 0 + (1 << 10) * 4);
    assert(row == row2);
    printf("new_row = %p\n", row2);
    printf("value = %u\n", (unsigned int)((*row2 & ~U_PTABLE_REGISTERED_MASK) >> U_PTABLE_ADDR_BITS));

    // printf("page table:\n");
    // print_ptable(&ptable);

    u_ptable_destroy(&ptable);
}

void test2()
{
    printf("%s\n", __func__);

    struct u_ptable_config cfg = {
        .flavor = U_PTABLE_OPENADDRESSING,
        .row_length_bits = 1,
        .num_ways_bits = 0,
        .offset_bits = 12,
        .lookup_bits = 4};
    struct u_ptable ptable;
    u_ptable_create(&ptable, u_mem_malloc_allocator, &cfg);

    for (int i = 0; i < 256; ++i)
    {
        u_ptable_elem_t *row = u_ptable_new(&ptable, i << 12);
        row[0] = U_PTABLE_REGISTERED_MASK | (i << 12);
        row[1] = 5;
    }

    for (int i = 0; i < 256; ++i)
    {
        u_ptable_elem_t *row = u_ptable_get(&ptable, i << 12);

        if (row[1] != 5)
        {
            printf("unexpected value: %d!?\n", i);
            return;
        }
    }

    printf("end capacity: %d\n", (int)u_ptable_info(&ptable)->capacity);
    printf("end linear probe range: %d\n", (int)u_ptable_info(&ptable)->linear_probe_range);
    // print_ptable(&ptable);

    u_ptable_destroy(&ptable);
}

void test3()
{
    printf("%s\n", __func__);

#define DATA_LENGTH (128 << 10)
#define DATA_RANGE (64 << 10)
    uint32_t data[DATA_LENGTH];
    uint32_t hist[DATA_RANGE];

    srand(time(0));

    memset(data, 0, sizeof(uint32_t) * DATA_LENGTH);
    memset(hist, 0, sizeof(uint32_t) * DATA_RANGE);

    for (uint32_t i = 0; i < DATA_LENGTH; ++i)
    {
        uint32_t x = rand() % DATA_RANGE;
        data[i] = x;
        hist[x]++;
    }
    size_t nonzero = 0;

    for (uint32_t i = 0; i < DATA_RANGE; ++i)
    {
        if (hist[i])
            nonzero++;
    }

    struct u_ptable_config cfg = {
        .flavor = U_PTABLE_OPENADDRESSING,
        .row_length_bits = 1,
        .num_ways_bits = 0,
        .offset_bits = 12,
        .lookup_bits = 0};

    struct u_ptable ptable;
    u_ptable_create(&ptable, u_mem_malloc_allocator, &cfg);

    for (uint32_t i = 0; i < DATA_LENGTH; ++i)
    {
        uint32_t x = data[i];
        u_ptable_elem_t *entry = u_ptable_get(&ptable, x << 12);
        if (!entry)
            entry = u_ptable_new(&ptable, x << 12);

        entry[1]++;
    }

    // print_ptable(&ptable);

    for (uint32_t i = 0; i < DATA_RANGE; ++i)
    {
        uint32_t expected = hist[i];

        u_ptable_elem_t *entry = u_ptable_get(&ptable, i << 12);

        if (expected == 0)
            continue;

        if (entry == NULL)
            printf("NULL entry at i = %u\n", (unsigned)i);

        if (entry[1] != expected)
            printf(
                "unexpected at i = %u, expected = %u and got = %u\n",
                (unsigned)i,
                (unsigned)expected,
                (unsigned)entry[1]);
    }

    u_ptable_destroy(&ptable);

#undef DATA_RANGE
#undef DATA_LENGTH
}

void test4()
{
    printf("%s\n", __func__);

#define DATA_LENGTH (128 << 10)
#define DATA_RANGE (64 << 10)
    uint32_t data[DATA_LENGTH];
    uint32_t hist[DATA_RANGE];

    srand(time(0));

    memset(data, 0, sizeof(uint32_t) * DATA_LENGTH);
    memset(hist, 0, sizeof(uint32_t) * DATA_RANGE);

    for (uint32_t i = 0; i < DATA_LENGTH; ++i)
    {
        uint32_t x = rand() % DATA_RANGE;
        data[i] = x;
        hist[x]++;
    }
    size_t nonzero = 0;

    for (uint32_t i = 0; i < DATA_RANGE; ++i)
    {
        if (hist[i])
            nonzero++;
    }

    struct u_ptable_config cfg = {
        .flavor = U_PTABLE_SETASSOCIATIVE,
        .row_length_bits = 1,
        .num_ways_bits = 8,
        .offset_bits = 12,
        .lookup_bits = 0};

    struct u_ptable ptable;
    u_ptable_create(&ptable, u_mem_malloc_allocator, &cfg);

    for (uint32_t i = 0; i < DATA_LENGTH; ++i)
    {
        uint32_t x = data[i];
        u_ptable_elem_t *entry = u_ptable_get(&ptable, x << 12);
        if (!entry)
            entry = u_ptable_new(&ptable, x << 12);
        
        while (!entry)
        {
            u_ptable_expandonce(&ptable);
            entry = u_ptable_new(&ptable, x << 12);
        }

        entry[1]++;
    }

    // print_ptable(&ptable);

    for (uint32_t i = 0; i < DATA_RANGE; ++i)
    {
        uint32_t expected = hist[i];

        u_ptable_elem_t *entry = u_ptable_get(&ptable, i << 12);

        if (expected == 0)
            continue;

        if (entry == NULL)
        {
            printf("NULL entry at i = %u\n", (unsigned)i);
            continue;
        }

        if (entry[1] != expected)
            printf(
                "unexpected at i = %u, expected = %u and got = %u\n",
                (unsigned)i,
                (unsigned)expected,
                (unsigned)entry[1]);
    }

    struct u_ptable_info const *info = u_ptable_info(&ptable);

    if (info->used != nonzero)
    {
        printf("used (%u) != nonzero (%u)\n", (unsigned)info->used, (unsigned)nonzero);
    }

    printf("Utilization: %f\n", (float)info->used / (float)info->capacity);
    u_ptable_destroy(&ptable);

#undef DATA_RANGE
#undef DATA_LENGTH
}

int main()
{
    test1();
    test2();
    test3();
    test4();
    return 0;
}
