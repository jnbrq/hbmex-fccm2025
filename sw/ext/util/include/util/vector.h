#ifndef UTIL_VECTOR_H_INCLUDED
#define UTIL_VECTOR_H_INCLUDED

#include "mem.h"

#ifdef __cplusplus
extern "C" {
#endif

struct u_vector {
    /// @brief length of the vector
    size_t length;

    /// @brief data
    char * data;

    size_t _elem_size;
    size_t _size;
    struct u_mem_block _block;
    struct u_mem_allocator * _allocator;
};

/**
 * @brief Initializes a vector from a memory allocator and element size.
 * 
 * @param vector 
 * @param allocator 
 * @param elem_size 
 */
void u_vector_create(struct u_vector *vector, struct u_mem_allocator *allocator, size_t elem_size);

/**
 * @brief Initializes a vector from a memory allocator and element size, with the given initial capacity.
 * 
 * @param vector 
 * @param allocator 
 * @param elem_size 
 * @param init_capacity 
 */
void u_vector_create2(struct u_vector *vector, struct u_mem_allocator *allocator, size_t elem_size, size_t init_capacity);

/**
 * @brief Destroys a vector.
 * 
 * @param vector 
 */
void u_vector_destroy(struct u_vector *vector);

/**
 * @brief Pushes back an element into the vector.
 * 
 * @param vector 
 * @param elem Element, if NULL, initializes with zero.
 * @return void* Pointer to the newly added element.
 */
void *u_vector_push(struct u_vector *vector, void const *elem);

/**
 * @brief Pushes back multiple elements, initialized.
 * 
 * @param vector 
 * @param length 
 * @param elem Element to initialize with, if NULL, initializes with zero.
 * @return void* Pointer to the newly added elements.
 */
void *u_vector_push_n(struct u_vector *vector, size_t length, void const *elem);

/**
 * @brief Pushes back multiple elements, uninitialized.
 * 
 * @param vector 
 * @param length 
 * @return void* Pointer to the newly added elements.
 */
void *u_vector_push_n2(struct u_vector *vector, size_t length);

/**
 * @brief Pops a single element from the vector.
 * 
 * @param vector 
 */
void u_vector_pop(struct u_vector *vector);

/**
 * @brief Clears the vector.
 * 
 * @param vector 
 */
void u_vector_clear(struct u_vector *vector);

/**
 * @brief Ensures that the vector has at least the given capacity.
 * 
 * @param vector 
 * @param capacity Capacity.
 */
void u_vector_grow(struct u_vector *vector, size_t capacity);

/**
 * @brief Ensures that the vector has at least the given capacity.
 * 
 * @param vector 
 * @param capacity_bytes Capacity is in bytes.
 */
void u_vector_grow2(struct u_vector *vector, size_t capacity_bytes);

/// @brief Iterates over a vector. sizeof(type) must be as initialized.
#define U_VECTOR_ITERATE(type, var, vec) \
    for (type (* var) = (type (*))((vec).data); \
    var != ((type (*))((vec).data) + (vec).length); \
    ++var)

#ifdef __cplusplus
}
#endif

#endif /* UTIL_VECTOR_H_INCLUDED */
