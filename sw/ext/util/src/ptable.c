#include <util/ptable.h>
#include <util/misc.h>
#include <error/assert.h>
#include <error/error.h>

#include <string.h>
#include <assert.h>

#define MIN(x, y) (((x) < (y)) ? (x) : (y))
#define MAX(x, y) (((x) > (y)) ? (x) : (y))

// TODO make this one dependent on the target type: host/uP
#define U_PTABLE_REGULARIZE_BUFFER_SIZE     64

void u_ptable_create(
    struct u_ptable *ptable,
    struct u_mem_allocator *allocator,
    struct u_ptable_config const *cfg)
{
    E_ASSERT(ptable != NULL);
    struct u_ptable_info *info = &ptable->_.info;

    E_ASSERT(allocator != NULL);
    E_ASSERT(cfg != NULL);

    E_ASSERT(
        cfg->flavor == U_PTABLE_OPENADDRESSING || cfg->flavor == U_PTABLE_SETASSOCIATIVE);

    uint32_t offset_bits, row_length_bits, num_ways_bits, lookup_bits;

    offset_bits = cfg->offset_bits;
    row_length_bits = cfg->row_length_bits;
    num_ways_bits =
        cfg->flavor == U_PTABLE_OPENADDRESSING ? 0 : cfg->num_ways_bits;
    lookup_bits = cfg->lookup_bits;

    ptable->_.allocator = allocator;

    info->flavor = cfg->flavor;
    info->offset_bits = offset_bits;
    info->offset_mask = (((u_ptable_elem_t)1) << offset_bits) - 1;
    info->lookup_bits = lookup_bits;
    info->lookup_mask = (((u_ptable_elem_t)1) << lookup_bits) - 1;
    info->num_sets = ((u_ptable_elem_t)1) << lookup_bits;
    info->row_length_bits = row_length_bits;
    info->row_length = ((uint32_t)1) << row_length_bits;
    info->row_size = sizeof(u_ptable_elem_t) << (info->row_length_bits);
    info->num_ways_bits = num_ways_bits;
    info->num_ways = ((uint32_t)1) << num_ways_bits;
    info->linear_probe_range = 0;

    size_t capacity = ((u_ptable_elem_t)1) << (lookup_bits + num_ways_bits);
    size_t size =
        sizeof(u_ptable_elem_t) * ((u_ptable_elem_t)1) << (lookup_bits + num_ways_bits + row_length_bits);

    info->capacity = capacity;
    info->used = 0;

    E_ERR_IF_DIE(u_mem_alloc(allocator, &ptable->_.storage, size), "alloc");
    memset(ptable->_.storage.data, 0, size);
}

void u_ptable_destroy(struct u_ptable *ptable)
{
    u_mem_free(ptable->_.allocator, &ptable->_.storage);
}

u_ptable_elem_t *u_ptable_get(struct u_ptable const *ptable, u_ptable_elem_t addr)
{
    E_ASSERT(ptable != NULL);
    struct u_ptable_info const *info = &ptable->_.info;

    E_ASSERT(U_PTABLE_STATE(addr) == 0);
    E_ASSERT((addr & info->offset_mask) == 0);

    u_ptable_elem_t *table = (u_ptable_elem_t *)ptable->_.storage.data;

    if (info->flavor == U_PTABLE_SETASSOCIATIVE)
    {
        u_ptable_index_t setidx = (addr >> info->offset_bits) & info->lookup_mask;
        u_ptable_elem_t *set = table + (setidx << (info->row_length_bits + info->num_ways_bits));

        for (uint32_t wayidx = 0; wayidx < info->num_ways; ++wayidx)
        {
            u_ptable_index_t *way = set + (wayidx << (info->row_length_bits));

            if (U_PTABLE_REGISTERED(way[0]) && U_PTABLE_ADDR(way[0]) == addr)
                return way;
        }

        return NULL;
    }
    else /* info->flavor == U_PTABLE_OPENADDRESSING */
    {
        u_ptable_index_t setidx = (addr >> info->offset_bits) & info->lookup_mask;

        for (u_ptable_elem_t i = 0; i < info->linear_probe_range; ++i)
        {
            u_ptable_elem_t *entry = table + (setidx << info->row_length_bits);

            if (U_PTABLE_REGISTERED(entry[0]) && U_PTABLE_ADDR(entry[0]) == addr)
                return entry;

            setidx = (setidx + 1) & info->lookup_mask;
        }

        return NULL;
    }
}

static u_ptable_elem_t *u_ptable_new_sa(struct u_ptable *ptable, u_ptable_elem_t addr)
{
    E_ASSERT(ptable != NULL);
    struct u_ptable_info *info = &ptable->_.info;

    E_ASSERT(info->flavor == U_PTABLE_SETASSOCIATIVE);
    E_ASSERT(U_PTABLE_STATE(addr) == 0);
    E_ASSERT((addr & info->offset_mask) == 0);

    u_ptable_elem_t *table = (u_ptable_elem_t *)ptable->_.storage.data;
    u_ptable_index_t setidx = (addr >> info->offset_bits) & info->lookup_mask;
    u_ptable_elem_t *set = table + (setidx << (info->row_length_bits + info->num_ways_bits));

    for (u_ptable_index_t wayidx = 0; wayidx < info->num_ways; ++wayidx)
    {
        u_ptable_index_t *way = set + (wayidx << (info->row_length_bits));

        if (U_PTABLE_REGISTERED(way[0]))
            continue;
        else
        {
            way[0] = U_PTABLE_REGISTERED_MASK | addr;
            return way;
        }
    }

    return NULL;
}

static u_ptable_elem_t *u_ptable_new_oa(struct u_ptable *ptable, u_ptable_elem_t addr)
{
    E_ASSERT(ptable != NULL);
    struct u_ptable_info *info = &ptable->_.info;

    E_ASSERT(info->flavor == U_PTABLE_OPENADDRESSING);
    E_ASSERT(U_PTABLE_STATE(addr) == 0);
    E_ASSERT((addr & info->offset_mask) == 0);

    u_ptable_elem_t *table = (u_ptable_elem_t *)ptable->_.storage.data;
    u_ptable_index_t setidx = (addr >> info->offset_bits) & info->lookup_mask;

    u_ptable_elem_t linear_probe_range = 0;
    u_ptable_elem_t *entry = NULL;

    while (1)
    {
        entry = table + (setidx << info->row_length_bits);
        linear_probe_range++;

        if (U_PTABLE_REGISTERED(entry[0]))
            E_ASSERT(addr != U_PTABLE_ADDR(entry[0]));
        else
            break;

        setidx = (setidx + 1) & info->lookup_mask;
    }

    // guaranteed to find an empty space
    entry[0] = U_PTABLE_REGISTERED_MASK | addr;
    info->linear_probe_range = MAX(linear_probe_range, info->linear_probe_range);
    return entry;
}

u_ptable_elem_t *u_ptable_new(struct u_ptable *ptable, u_ptable_elem_t addr)
{
    E_ASSERT(ptable != NULL);
    struct u_ptable_info *info = &ptable->_.info;

    E_ASSERT(U_PTABLE_STATE(addr) == 0);
    E_ASSERT((addr & info->offset_mask) == 0);

    if (info->used * 4 > info->capacity * 3)
        u_ptable_expandonce(ptable);

    if (info->used == info->capacity)
        return NULL;

    u_ptable_elem_t *result = NULL;
    if (info->flavor == U_PTABLE_SETASSOCIATIVE)
        result = u_ptable_new_sa(ptable, addr);
    else /* info->flavor == U_PTABLE_OPENADDRESSING */
        result = u_ptable_new_oa(ptable, addr);

    if (result != NULL)
        info->used++;

    return result;
}

void u_ptable_remove(struct u_ptable *ptable, u_ptable_elem_t *entry)
{
    E_ASSERT(ptable != NULL);
    struct u_ptable_info *info = &ptable->_.info;

    if (info->used > 0)
        info->used--;

    memset(entry, 0, sizeof(u_ptable_elem_t) * info->row_length);
}

/// @brief Redistributes the elements in a set-associative page table.
/// @param ptable
static void u_ptable_regularize_sa(struct u_ptable *ptable)
{
    E_ASSERT(ptable != NULL);
    struct u_ptable_info const *info = &ptable->_.info;
    E_ASSERT(info->flavor == U_PTABLE_SETASSOCIATIVE);
    u_ptable_elem_t *table = (u_ptable_elem_t *)ptable->_.storage.data;
    u_ptable_elem_t num_sets = info->num_sets >> 1;

    char buffer[U_PTABLE_REGULARIZE_BUFFER_SIZE];
    E_ASSERT(info->row_size <= U_PTABLE_REGULARIZE_BUFFER_SIZE);

    for (u_ptable_index_t setidx = 0; setidx < num_sets; ++setidx)
    {
        u_ptable_elem_t *set = table + (setidx << (info->num_ways_bits + info->row_length_bits));

        for (u_ptable_index_t wayidx = 0; wayidx < info->num_ways; ++wayidx)
        {
            u_ptable_elem_t *way = set + (wayidx << (info->row_length_bits));

            if (U_PTABLE_REGISTERED(way[0]))
            {
                u_ptable_elem_t addr = U_PTABLE_ADDR(way[0]);
                u_ptable_index_t setidx_expected = (addr >> info->offset_bits) & info->lookup_mask;

                if (setidx != setidx_expected)
                {
                    // this entry does not belong in here
                    memcpy(buffer, way, info->row_size);
                    memset(way, 0, info->row_size);

                    u_ptable_elem_t *new_entry = u_ptable_new_sa(ptable, addr);
                    E_ASSERT(new_entry != NULL);
                    memcpy(new_entry, buffer, info->row_size);
                }
            }
        }
    }
}

/// @brief Redistributes the elements in a open-addressed page table.
/// @param ptable
void u_ptable_regularize_oa(struct u_ptable *ptable)
{
    E_ASSERT(ptable != NULL);
    struct u_ptable_info *info = &ptable->_.info;
    E_ASSERT(info->flavor == U_PTABLE_OPENADDRESSING);
    u_ptable_elem_t *table = (u_ptable_elem_t *)ptable->_.storage.data;
    u_ptable_elem_t num_sets = info->num_sets >> 1;

    char buffer[U_PTABLE_REGULARIZE_BUFFER_SIZE];
    E_ASSERT(info->row_size <= U_PTABLE_REGULARIZE_BUFFER_SIZE);

    info->linear_probe_range = 0;
    for (u_ptable_index_t setidx = 0; setidx < num_sets; ++setidx)
    {
        u_ptable_elem_t *entry = table + (setidx << (info->row_length_bits + info->num_ways_bits));

        if (U_PTABLE_REGISTERED(entry[0]))
        {
            u_ptable_elem_t addr = U_PTABLE_ADDR(entry[0]);
            memcpy(buffer, entry, info->row_size);
            memset(entry, 0, info->row_size);

            u_ptable_elem_t *new_entry = u_ptable_new_oa(ptable, addr);
            E_ASSERT(new_entry != NULL);
            memcpy(new_entry, buffer, info->row_size);
        }
    }
}

u_result_t u_ptable_expandonce(struct u_ptable *ptable)
{
    E_ASSERT(ptable != NULL);
    struct u_ptable_info *info = &ptable->_.info;
    struct u_mem_block *storage = &ptable->_.storage;

    if ((info->capacity << 8 /* safety margin */) == 0)
        // NOTE assumes that size_table is a power of two
        // size overflows, so fail
        return U_FAILURE;

    if (u_mem_realloc(ptable->_.allocator, storage, storage->size << 1) < 0)
        // cannot allocate, so fail
        return U_FAILURE;

    // make sure that the newly allocated portion of the page table is reset
    memset(storage->data + (storage->size >> 1), 0, (storage->size >> 1));

    info->lookup_bits++;
    info->lookup_mask = (info->lookup_mask << 1) | 1;
    info->num_sets <<= 1;
    info->capacity <<= 1;

    if (info->flavor == U_PTABLE_SETASSOCIATIVE)
        u_ptable_regularize_sa(ptable);
    else /* info->flavor == U_PTABLE_OPENADDRESSING */
        u_ptable_regularize_oa(ptable);

    return U_SUCCESS;
}

u_ptable_elem_t *u_ptable_data(struct u_ptable *ptable)
{
    E_ASSERT(ptable != NULL);
    return (u_ptable_elem_t *)ptable->_.storage.data;
}

void u_ptable_iter(
    struct u_ptable const *ptable,
    u_ptable_elem_t **begin,
    u_ptable_elem_t **end,
    size_t *step_set,
    size_t *num_ways,
    size_t *step_way)
{
    E_ASSERT(ptable != NULL);
    struct u_ptable_info const *info = &ptable->_.info;

    E_ASSERT(begin != NULL);
    E_ASSERT(end != NULL);
    E_ASSERT(step_set != NULL);
    E_ASSERT(num_ways != NULL);
    E_ASSERT(step_way != NULL);

    *begin = (u_ptable_elem_t *)ptable->_.storage.data;
    *end = *begin + (((size_t)1) << (info->lookup_bits + info->num_ways_bits + info->row_length_bits));
    *step_set = ((size_t)1) << (info->num_ways_bits + info->row_length_bits);
    *num_ways = ((size_t)1) << info->num_ways_bits;
    *step_way = ((size_t)1) << info->row_length_bits;
}

struct u_ptable_info const *u_ptable_info(struct u_ptable const *ptable)
{
    return &ptable->_.info;
}
