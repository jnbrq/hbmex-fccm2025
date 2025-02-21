#ifndef UTIL_CQUEUE_H_INCLUDED
#define UTIL_CQUEUE_H_INCLUDED

#include <stdint.h>
#include <error/error.h>

#include "mem.h"
#include "vector.h"

#ifdef __cplusplus
extern "C"
{
#endif

struct u_cqueue
{
    struct {
        size_t length;

        size_t begin;
        size_t rbegin;

        size_t end;
        size_t rend;

        size_t elem_size;
        size_t size;

        struct u_mem_block block;
        struct u_mem_allocator *allocator;
    } _;
};

u_result_t u_cqueue_create(
    struct u_cqueue *cqueue,
    struct u_mem_allocator *allocator,
    size_t elem_size,
    size_t capacity);

void u_cqueue_destroy(struct u_cqueue *cqueue);

size_t u_cqueue_length(struct u_cqueue *cqueue);

u_result_t u_cqueue_pushback(struct u_cqueue *cqueue, void const *elem);
u_result_t u_cqueue_popback(struct u_cqueue *cqueue);

u_result_t u_cqueue_pushfront(struct u_cqueue *cqueue, void const *elem);
u_result_t u_cqueue_popfront(struct u_cqueue *cqueue);

u_result_t u_cqueue_clear(struct u_cqueue *cqueue);

int u_cqueue_empty(struct u_cqueue *cqueue);
int u_cqueue_full(struct u_cqueue *cqueue);

// TODO complete
#define U_CQUEUE_ITERATE(type, var, cqueue)

#define U_CQUEUE_LENGTH(cqueue) ((cqueue)._.length)

#define U_CQUEUE_FIRST(cqueue, type) \
    ((type(*))((cqueue)._.block.data + (cqueue)._.begin))

#define U_CQUEUE_LAST(cqueue, type) \
    ((type(*))((cqueue)._.block.data + (cqueue)._.rbegin))

#define U_CQUEUE_AT(cqueue, type, idx) \
    ((type(*))((cqueue)._.block.data +  \
               (((idx) * (cqueue)._.elem_size + (cqueue)._.begin) % (cqueue)._.block.size)))

#ifdef __cplusplus
}
#endif

#endif /* UTIL_CQUEUE_H_INCLUDED */
