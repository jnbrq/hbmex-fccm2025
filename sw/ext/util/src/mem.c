#ifndef U_MEM_NO_MMAP_ALLOCATOR
#   define _GNU_SOURCE
#   include <sys/mman.h>
#   include <unistd.h>
#endif

#include <string.h>

#include <error/assert.h>
#include <util/mem.h>
#include <util/misc.h>

u_result_t u_mem_alloc(struct u_mem_allocator *allocator, struct u_mem_block *block, size_t size)
{
    return allocator->alloc(allocator, block, size);
}

u_result_t u_mem_realloc(struct u_mem_allocator *allocator, struct u_mem_block *block, size_t new_size)
{
    return allocator->realloc(allocator, block, new_size);
}

void u_mem_free(struct u_mem_allocator *allocator, struct u_mem_block *block)
{
    allocator->free(allocator, block);
}

void u_mem_block_init(struct u_mem_block *block)
{
    block->size = 0;
    block->data = NULL;
}

#ifndef U_MEM_NO_MMAP_ALLOCATOR

static size_t align_mask_ceil(size_t x, size_t mask)
{
    return (x & mask) ? (1 + (x | mask)) : x;
}

static size_t align_mask_floor(size_t x, size_t mask)
{
    return x & ~mask;
}

static u_result_t mmap_alloc(struct u_mem_allocator *allocator, struct u_mem_block *block, size_t size)
{
    size = align_mask_ceil(size, sysconf(_SC_PAGE_SIZE) - 1);

    void *data = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_POPULATE, -1, 0);

    if (data == MAP_FAILED)
        return U_FAILURE;

    block->size = size;
    block->data = (char *)data;

    return U_SUCCESS;
}

static void mmap_free(struct u_mem_allocator *allocator, struct u_mem_block *block)
{
    munmap(block->data, block->size);

    block->data = NULL;
    block->size = 0;
}

static u_result_t mmap_realloc(struct u_mem_allocator *allocator, struct u_mem_block *block, size_t new_size)
{
    if (block->data == NULL || block->size == 0)
        return mmap_alloc(allocator, block, new_size);

#if 0
    // mremap can fail with a SIGBUS
    //      https://www.spinics.net/lists/linux-mm/msg214704.html
    //      https://bugzilla.kernel.org/show_bug.cgi?id=8691
    new_size = align_mask_ceil(new_size, sysconf(_SC_PAGE_SIZE) - 1);

    block->data = mremap(block->data, block->size, new_size, MREMAP_MAYMOVE);
    block->size = new_size;
#endif

    struct u_mem_block new_block;

    if (mmap_alloc(allocator, &new_block, new_size) != U_SUCCESS)
        return U_FAILURE;

    memcpy(new_block.data, block->data, block->size);
    mmap_free(allocator, block);
    *block = new_block;

    return U_SUCCESS;
}


struct u_mem_allocator u_mem_mmap_allocator[1] = {
    {.alloc = mmap_alloc,
     .realloc = mmap_realloc,
     .free = mmap_free}};

#endif

#ifndef U_MEM_NO_MALLOC_ALLOCATOR

#include <stdlib.h>

static u_result_t malloc_alloc(struct u_mem_allocator *allocator, struct u_mem_block *block, size_t size)
{
    void *data = malloc(size);

    if (data == NULL)
        return U_FAILURE;

    block->data = (char *)data;
    block->size = size;

    return U_SUCCESS;
}

static u_result_t malloc_realloc(struct u_mem_allocator *allocator, struct u_mem_block *block, size_t new_size)
{
    E_ASSERT(new_size >= block->size);

    if (block->data == NULL || block->size == 0)
        return malloc_alloc(allocator, block, new_size);

    void *data = realloc(block->data, new_size);
    memset(data + block->size, 0, new_size - block->size);

    if (data == NULL)
        return U_FAILURE;

    block->data = (char *)data;
    block->size = new_size;

    return U_SUCCESS;
}

static void malloc_free(struct u_mem_allocator *allocator, struct u_mem_block *block)
{
    free(block->data);

    block->data = NULL;
    block->size = 0;
}

struct u_mem_allocator u_mem_malloc_allocator[1] = {
    {.alloc = malloc_alloc,
     .realloc = malloc_realloc,
     .free = malloc_free}};

#endif

static u_result_t linear_alloc(struct u_mem_allocator *allocator, struct u_mem_block *block, size_t size)
{
    struct u_mem_linear_allocator *linear_allocator = container_of(allocator, struct u_mem_linear_allocator, allocator);

    uintptr_t next = linear_allocator->next + size;

    if (next > linear_allocator->size)
        return U_FAILURE;

    block->data = linear_allocator->data + linear_allocator->next;
    block->size = size;
    memset(linear_allocator->data, 0, block->size);

    linear_allocator->next = next;
    linear_allocator->num_blocks++;

    return U_SUCCESS;
}

static void linear_free(struct u_mem_allocator *allocator, struct u_mem_block *block)
{
    struct u_mem_linear_allocator *linear_allocator = container_of(allocator, struct u_mem_linear_allocator, allocator);

    block->data = NULL;
    block->size = 0;

    linear_allocator->num_blocks--;

    if (linear_allocator->num_blocks == 0)
        linear_allocator->next = 0;
}

static u_result_t linear_realloc(struct u_mem_allocator *allocator, struct u_mem_block *block, size_t new_size)
{
    struct u_mem_linear_allocator *linear_allocator = container_of(allocator, struct u_mem_linear_allocator, allocator);

    E_ASSERT(new_size >= block->size);
    
    uintptr_t tail = (uintptr_t)linear_allocator->data + linear_allocator->next;
    uintptr_t block_end = (uintptr_t)block->data + block->size;
    uintptr_t extend = new_size - block->size;

    if (tail == block_end)
    {
        uintptr_t next = linear_allocator->next + extend;

        if (next > linear_allocator->size)
            return U_FAILURE;

        memset(block->data + block->size, 0, extend);

        block->size = new_size;
        linear_allocator->next = next;
    }
    else
    {
        // not the tail, allocate new and copy

        struct u_mem_block new_block;

        uintptr_t next = linear_allocator->next + new_size;

        if (next > linear_allocator->size)
            return U_FAILURE;
        
        new_block.data = linear_allocator->data + linear_allocator->next;
        new_block.size = new_size;

        memcpy(new_block.data, block->data, block->size);
        memset(new_block.data + block->size, 0, new_size - block->size);

        *block = new_block;
        linear_allocator->next = next;
    }

    return U_SUCCESS;
}

void u_mem_linear_allocator_init(
    struct u_mem_linear_allocator *linear_allocator,
    char *data,
    size_t size)
{
    linear_allocator->allocator.alloc = &linear_alloc;
    linear_allocator->allocator.realloc = &linear_realloc;
    linear_allocator->allocator.free = &linear_free;

    linear_allocator->data = data;
    linear_allocator->size = size;
    linear_allocator->next = 0;
    linear_allocator->num_blocks = 0;
}
