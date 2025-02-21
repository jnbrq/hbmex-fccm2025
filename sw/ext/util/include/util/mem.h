#ifndef UTIL_MEM_H_INCLUDED
#define UTIL_MEM_H_INCLUDED

#include "defs.h"

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C"
{
#endif

struct u_mem_allocator;
struct u_mem_block;

/// @brief Allocation function for the given memory allocator.
typedef u_result_t (*u_mem_alloc_func_t)(struct u_mem_allocator *allocator, struct u_mem_block *block, size_t size);

/// @brief Reallocation function for the given memory allocator. Must retain the contents.
typedef u_result_t (*u_mem_realloc_func_t)(struct u_mem_allocator *allocator, struct u_mem_block *block, size_t new_size);

/// @brief Free function for the given memory allocator.
typedef void (*u_mem_free_func_t)(struct u_mem_allocator *allocator, struct u_mem_block *block);

struct u_mem_allocator {
    /// @brief allocation function
    u_mem_alloc_func_t alloc;

    /// @brief reallocation function
    u_mem_realloc_func_t realloc;

    /// @brief free function
    u_mem_free_func_t free;
};

struct u_mem_block {
    /// @brief block size
    size_t size;

    /// @brief block data
    char * data;
};

u_result_t u_mem_alloc(struct u_mem_allocator *allocator, struct u_mem_block *block, size_t size);
u_result_t u_mem_realloc(struct u_mem_allocator *allocator, struct u_mem_block *block, size_t new_size);
void u_mem_free(struct u_mem_allocator *allocator, struct u_mem_block *block);

void u_mem_block_init(struct u_mem_block *block);

#ifndef U_MEM_NO_MMAP_ALLOCATOR
extern struct u_mem_allocator u_mem_mmap_allocator[1];
#endif

#ifndef U_MEM_NO_MALLOC_ALLOCATOR
extern struct u_mem_allocator u_mem_malloc_allocator[1];
#endif

struct u_mem_linear_allocator {
    struct u_mem_allocator allocator;

    char * data;
    size_t size;
    uintptr_t next;
    uint32_t num_blocks;
};

void u_mem_linear_allocator_init(
    struct u_mem_linear_allocator *linear_allocator,
    char *data,
    size_t size);

#ifdef __cplusplus
}
#endif

#endif /* UTIL_MEM_H_INCLUDED */
