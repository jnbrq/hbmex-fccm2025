#include <util/vector.h>
#include <string.h>

void u_vector_create(struct u_vector *vector, struct u_mem_allocator *allocator, size_t elem_size)
{
    // initially, host at least 4 elements
    u_vector_create2(vector, allocator, elem_size, 4);
}

void u_vector_create2(struct u_vector *vector, struct u_mem_allocator *allocator, size_t elem_size, size_t init_capacity)
{
    vector->length = 0;
    vector->data = NULL;

    vector->_elem_size = elem_size;
    vector->_size = 0;
    vector->_allocator = allocator;
    u_mem_block_init(&vector->_block);

    u_vector_grow(vector, init_capacity);
}

void u_vector_destroy(struct u_vector *vector)
{
    u_mem_free(vector->_allocator, &vector->_block);
}

void *u_vector_push(struct u_vector *vector, void const *elem)
{
    if (vector->_size + vector->_elem_size > vector->_block.size)
        u_vector_grow2(vector, vector->_block.size * 2);
    // NOTE we should make the grow coefficient a float and configurable?

    void *ptr = vector->data + vector->_size;

    if (elem != NULL)
        memcpy(ptr, elem, vector->_elem_size);
    else
        memset(ptr, 0, vector->_elem_size);

    vector->length++;
    vector->_size += vector->_elem_size;

    return ptr;
}

void *u_vector_push_n(struct u_vector *vector, size_t length, void const *elem)
{
    void *ptr = u_vector_push_n2(vector, length);

    if (elem == NULL)
    {
        memset(ptr, 0, vector->_elem_size * length);
        return ptr;
    }

    for (size_t i = 0; i < length; ++i)
    {
        memcpy(ptr + i * vector->_elem_size, elem, vector->_elem_size);
    }

    return ptr;
}

void *u_vector_push_n2(struct u_vector *vector, size_t length)
{
    size_t old_size = vector->_size;
    size_t requested_size = old_size + length * vector->_elem_size;
    if (requested_size > vector->_block.size)
        u_vector_grow2(vector, requested_size);
    
    vector->length += length;
    vector->_size += length * vector->_elem_size;

    return vector->data + old_size;
}

void u_vector_pop(struct u_vector *vector)
{
    if (vector->length == 0)
        return;

    vector->length--;
    vector->_size -= vector->_elem_size;
}

void u_vector_clear(struct u_vector *vector)
{
    vector->length = 0;
    vector->_size = 0;
}

void u_vector_grow(struct u_vector *vector, size_t capacity)
{
    u_mem_realloc(vector->_allocator, &vector->_block, capacity * vector->_elem_size);
    vector->data = vector->_block.data;
}

void u_vector_grow2(struct u_vector *vector, size_t capacity_bytes)
{
    u_mem_realloc(vector->_allocator, &vector->_block, capacity_bytes);
    vector->data = vector->_block.data;
}
