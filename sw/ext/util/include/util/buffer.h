#ifndef UTIL_BUFFER_H_INCLUDED
#define UTIL_BUFFER_H_INCLUDED

#include <stddef.h>
#include <string.h>
#include "defs.h"

#define U_BUFFER_DECLARE(PREFIX, TYPE)                                                                      \
    struct PREFIX##_buffer                                                                                  \
    {                                                                                                       \
        TYPE(*data);                                                                                        \
        size_t length;                                                                                      \
        size_t capacity;                                                                                    \
    };                                                                                                      \
                                                                                                            \
    void                                                                                                    \
        PREFIX##_buffer_init(struct PREFIX##_buffer *buffer, TYPE(*data), size_t capacity);                 \
                                                                                                            \
    void                                                                                                    \
        PREFIX##_buffer_init2(struct PREFIX##_buffer *buffer, TYPE(*data), size_t capacity, size_t length); \
                                                                                                            \
    u_result_t                                                                                              \
        PREFIX##_buffer_append(struct PREFIX##_buffer *buffer, TYPE(*item));                                \
                                                                                                            \
    void                                                                                                    \
        PREFIX##_buffer_clear(struct PREFIX##_buffer *buffer);                                              \
                                                                                                            \
    size_t PREFIX##_buffer_left(struct PREFIX##_buffer *buffer);

#define U_BUFFER_DEFINE(PREFIX, TYPE)                                                                      \
    void                                                                                                   \
        PREFIX##_buffer_init(struct PREFIX##_buffer *buffer, TYPE(*data), size_t capacity)                 \
    {                                                                                                      \
        PREFIX##_buffer_init2(buffer, data, capacity, 0);                                                  \
    }                                                                                                      \
                                                                                                           \
    void                                                                                                   \
        PREFIX##_buffer_init2(struct PREFIX##_buffer *buffer, TYPE(*data), size_t capacity, size_t length) \
    {                                                                                                      \
                                                                                                           \
        buffer->data = data;                                                                               \
        buffer->capacity = capacity;                                                                       \
        buffer->length = length;                                                                           \
    }                                                                                                      \
                                                                                                           \
    u_result_t                                                                                             \
        PREFIX##_buffer_append(struct PREFIX##_buffer *buffer, TYPE(*item))                                \
    {                                                                                                      \
                                                                                                           \
        if (buffer->length >= buffer->capacity)                                                            \
            return U_ECAPACITY;                                                                            \
                                                                                                           \
        memcpy(&buffer->data[buffer->length++], item, sizeof(TYPE));                                       \
                                                                                                           \
        return U_SUCCESS;                                                                                  \
    }                                                                                                      \
                                                                                                           \
    void                                                                                                   \
        PREFIX##_buffer_clear(struct PREFIX##_buffer *buffer)                                              \
    {                                                                                                      \
        buffer->length = 0;                                                                                \
    }                                                                                                      \
    size_t PREFIX##_buffer_left(struct PREFIX##_buffer *buffer)                                            \
    {                                                                                                      \
        return buffer->capacity - buffer->length;                                                          \
    }

#endif /* UTIL_BUFFER_H_INCLUDED */
