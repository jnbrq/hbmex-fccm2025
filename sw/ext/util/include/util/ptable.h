/**
 * @file ptable.h
 * @author Canberk Sönmez (canberk.sonmez.409@gmail.com)
 * @brief A simple hash-based page table.
 * @date 2023-04-25
 *
 * Copyright (c) Canberk Sönmez 2023
 *
 */

#ifndef UTIL_PTABLE_H_INCLUDED
#define UTIL_PTABLE_H_INCLUDED

#include "mem.h"
#include "vector.h"

#include <limits.h>
#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C"
{
#endif

    /**
     * @brief Element type used in the page table.
     * The most significant N-bits are used for storing state.
     *
     * @note Must be as large as possible for a pointer (56-bits).
     *
     */
    typedef uint64_t u_ptable_elem_t;

    /// @brief Indexes a page table row or set.
    typedef uint64_t u_ptable_index_t;

#define U_PTABLE_INVALID_INDEX ((u_ptable_index_t)-1)

// clang-format off

/// @brief Number of state bits.
#define U_PTABLE_STATE_BITS         8

/// @brief Element bits
#define U_PTABLE_ELEM_BITS          (sizeof(u_ptable_elem_t) * CHAR_BIT)

/// @brief Address bits
#define U_PTABLE_ADDR_BITS          (U_PTABLE_ELEM_BITS - U_PTABLE_STATE_BITS)

/// @brief Address mask
#define U_PTABLE_ADDR_MASK          ((((u_ptable_elem_t) 1) << U_PTABLE_ADDR_BITS) - 1)

/// @brief State mask
#define U_PTABLE_STATE_MASK         (~U_PTABLE_ADDR_MASK)

/// @brief Creates a mask, n counts from the MSB,
#define U_PTABLE_MAKE_STATE_MASK(n) (((u_ptable_elem_t) 1) << (U_PTABLE_ELEM_BITS - n - 1))

/// @brief Registered mask
#define U_PTABLE_REGISTERED_MASK    U_PTABLE_MAKE_STATE_MASK(0)

/// @brief Valid mask
#define U_PTABLE_VALID_MASK         U_PTABLE_MAKE_STATE_MASK(1)

/// @brief Exclusive mask
#define U_PTABLE_EXCLUSIVE_MASK     U_PTABLE_MAKE_STATE_MASK(2)

/// @brief Marked mask
#define U_PTABLE_MARKED_MASK        U_PTABLE_MAKE_STATE_MASK(4)

#define U_PTABLE_ADDR(expr)         ((expr) & U_PTABLE_ADDR_MASK)
#define U_PTABLE_STATE(expr)        ((expr) >> U_PTABLE_ADDR_BITS)
#define U_PTABLE_REGISTERED(expr)   (((expr) & U_PTABLE_REGISTERED_MASK) > 0)
#define U_PTABLE_VALID(expr)        (((expr) & U_PTABLE_VALID_MASK) > 0)
#define U_PTABLE_EXCLUSIVE(expr)    (((expr) & U_PTABLE_EXCLUSIVE_MASK) > 0)
#define U_PTABLE_MARKED(expr)       (((expr) & U_PTABLE_MARKED_MASK) > 0)

#include <error/assert.h>

/// @brief Checks the registered bit of the page table.
#define U_PTABLE_CHECK_R(elem) \
    E_ASSERT(U_PTABLE_REGISTERED(elem))

/// @brief Checks the valid and exclusive bits of the page table.
#define U_PTABLE_CHECK_SANITY(elem) \
    E_ASSERT(!(!U_PTABLE_VALID(elem) && U_PTABLE_EXCLUSIVE(elem)))

    // clang-format on

#define U_PTABLE_ALIGN_PAGE(expr, offset_bits)           \
    ({                                                   \
        u_ptable_elem_t res = ((u_ptable_elem_t)(expr)); \
        res >>= (offset_bits);                           \
        res++;                                           \
        res << (offset_bits);                            \
    })

enum u_ptable_flavor
{
    /// @brief Linear probing.
    U_PTABLE_OPENADDRESSING,

    /// @brief No linear probing.
    U_PTABLE_SETASSOCIATIVE
};

struct u_ptable_config
{
    /// @brief Flavor.
    enum u_ptable_flavor flavor;

    /// @brief Row length bits, log2 of row length.
    uint32_t row_length_bits;

    /// @brief For set-associative page tables, log2 of the number of ways.
    uint32_t num_ways_bits;

    /// @brief Offset bits.
    uint32_t offset_bits;

    /// @brief Lookup bits to determine the size of the table.
    /// @note Can increase as new elements are added to the table.
    uint32_t lookup_bits;
};

struct u_ptable_info
{
    /// @brief Flavor.
    enum u_ptable_flavor flavor;

    /// @brief Offset bits.
    uint32_t offset_bits;

    /// @brief Offset mask.
    u_ptable_elem_t offset_mask;

    /// @brief Number of lookup bits.
    /// @note Might increase as the table grows.
    uint32_t lookup_bits;

    /// @brief Lookup mask.
    /// @note Might change as the table grows.
    u_ptable_elem_t lookup_mask;

    /// @brief Number of sets.
    u_ptable_elem_t num_sets;

    /// @brief Row length bits. (log2 of row length)
    uint32_t row_length_bits;

    /// @brief Row length.
    uint32_t row_length;

    /// @brief Row size (bytes).
    uint32_t row_size;

    /// @brief For set-associative page tables, log2 of the number of ways.
    uint32_t num_ways_bits;

    /// @brief For set-associative page tables, the number of ways.
    uint32_t num_ways;

    /// @brief Linear probe range.
    u_ptable_elem_t linear_probe_range;

    /// @brief Capacity in terms of number of entries.
    u_ptable_elem_t capacity;

    /// @brief Number of used elements.
    /// @note Used for deciding when to expand the page table.
    u_ptable_elem_t used;
};

struct u_ptable
{
    struct
    {
        /// @brief Memory allocator.
        struct u_mem_allocator *allocator;

        /// @brief Memory storage.
        struct u_mem_block storage;

        /// @brief Information regarding the page table.
        struct u_ptable_info info;
    } _;
};

/**
 * @brief Initializes a given page table.
 *
 * @param ptable page table to initialize.
 * @param allocator memory allocator for the table
 * @param cfg configuration.
 */
void u_ptable_create(
    struct u_ptable *ptable,
    struct u_mem_allocator *allocator,
    struct u_ptable_config const *cfg);

/**
 * @brief Destructs the given page table.
 *
 * @param ptable page table to destruct.
 */
void u_ptable_destroy(struct u_ptable *ptable);

/**
 * @brief Returns an entry from the page table.
 *
 * @param ptable page table for lookup. idx shall not contain any state bits.
 * @param idx Index to lookup.
 * @return u_ptable_elem_t* pointer to the entry. NULL if not found.
 */
u_ptable_elem_t *u_ptable_get(struct u_ptable const *ptable, u_ptable_elem_t addr);

/**
 * @brief Creates a new entry in the page table.
 *
 * @note For set-associative, returns NULL if there is no free space.
 * @note Internally updates the counters.
 *
 * @param ptable
 * @param addr
 * @return u_ptable_elem_t*
 */
u_ptable_elem_t *u_ptable_new(struct u_ptable *ptable, u_ptable_elem_t addr);

/**
 * @brief Removes an entry.
 *
 * @note Internally updates the counters.
 *
 * @param ptable
 * @param entry
 */
void u_ptable_remove(struct u_ptable *ptable, u_ptable_elem_t *entry);

/**
 * @brief Tries to expand the page table.
 *
 * @param ptable
 * @return u_result_t U_SUCCESS if success, U_FAILURE otherwise.
 */
u_result_t u_ptable_expandonce(struct u_ptable *ptable);

/**
 * @brief Returns a pointer to the table.
 *
 * @param ptable
 * @return u_ptable_elem_t*
 */
u_ptable_elem_t *u_ptable_data(struct u_ptable *ptable);

/**
 * @brief Initializes an iterator to iterate the entire table.
 * @note All output params are nullable.
 *
 * @param ptable
 * @param begin
 * @param end
 * @param step_set
 * @param num_ways
 * @param step_way
 */
void u_ptable_iter(
    struct u_ptable const *ptable,
    u_ptable_elem_t **begin,
    u_ptable_elem_t **end,
    size_t *step_set,
    size_t *num_ways,
    size_t *step_way);

/**
 * @brief Returns a pointer to the internal params of the page table.
 *
 * @param ptable
 */
struct u_ptable_info const *u_ptable_info(struct u_ptable const *ptable);

#ifdef __cplusplus
}
#endif

#endif /* UTIL_PTABLE_H_INCLUDED */
