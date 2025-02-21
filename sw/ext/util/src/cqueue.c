#include <util/cqueue.h>

#include <string.h>

#define U_CQUEUE_INCREMENT(var) \
    cqueue->var += cqueue->_.elem_size

#define U_CQUEUE_DECREMENT(var) \
    cqueue->var -= cqueue->_.elem_size

#define U_CQUEUE_EXPAND(var) \
    cqueue->var += cqueue->_.block.size

#define U_CQUEUE_NORMALIZE(var)             \
    if (cqueue->var >= cqueue->_.block.size) \
    cqueue->var -= cqueue->_.block.size

u_result_t u_cqueue_create(
    struct u_cqueue *cqueue,
    struct u_mem_allocator *allocator,
    size_t elem_size,
    size_t capacity)
{
    // TODO check for the return value
    u_mem_alloc(allocator, &cqueue->_.block, capacity * elem_size);

    cqueue->_.allocator = allocator;
    cqueue->_.elem_size = elem_size;

    u_cqueue_clear(cqueue);

    return U_SUCCESS;
}

void u_cqueue_destroy(struct u_cqueue *cqueue)
{
    if (cqueue->_.allocator)
        u_mem_free(cqueue->_.allocator, &cqueue->_.block);
}

size_t u_cqueue_length(struct u_cqueue *cqueue)
{
    return cqueue->_.length;
}

u_result_t u_cqueue_pushback(struct u_cqueue *cqueue, void const *elem)
{
    if (cqueue->_.size >= cqueue->_.block.size)
        return U_ECAPACITY;

    cqueue->_.size += cqueue->_.elem_size;
    cqueue->_.length++;

    if (elem != NULL)
        memcpy(cqueue->_.block.data + cqueue->_.end, elem, cqueue->_.elem_size);
    else
        memset(cqueue->_.block.data + cqueue->_.end, 0, cqueue->_.elem_size);

    U_CQUEUE_INCREMENT(_.end);
    U_CQUEUE_INCREMENT(_.rbegin);

    U_CQUEUE_NORMALIZE(_.end);
    U_CQUEUE_NORMALIZE(_.rbegin);

    return U_SUCCESS;
}

u_result_t u_cqueue_popback(struct u_cqueue *cqueue)
{
    if (cqueue->_.size == 0)
        return U_EEMPTY;

    cqueue->_.size -= cqueue->_.elem_size;
    cqueue->_.length--;

    U_CQUEUE_EXPAND(_.end);
    U_CQUEUE_EXPAND(_.rbegin);

    U_CQUEUE_DECREMENT(_.end);
    U_CQUEUE_DECREMENT(_.rbegin);

    U_CQUEUE_NORMALIZE(_.end);
    U_CQUEUE_NORMALIZE(_.rbegin);

    return U_SUCCESS;
}

u_result_t u_cqueue_pushfront(struct u_cqueue *cqueue, void const *elem)
{
    if (cqueue->_.size >= cqueue->_.block.size)
        return U_ECAPACITY;

    cqueue->_.size += cqueue->_.elem_size;
    cqueue->_.length++;

    if (elem != NULL)
        memcpy(cqueue->_.block.data + cqueue->_.rend, elem, cqueue->_.elem_size);
    else
        memset(cqueue->_.block.data + cqueue->_.rend, 0, cqueue->_.elem_size);

    U_CQUEUE_EXPAND(_.rend);
    U_CQUEUE_EXPAND(_.begin);

    U_CQUEUE_DECREMENT(_.rend);
    U_CQUEUE_DECREMENT(_.begin);

    U_CQUEUE_NORMALIZE(_.rend);
    U_CQUEUE_NORMALIZE(_.begin);

    return U_SUCCESS;
}

u_result_t u_cqueue_popfront(struct u_cqueue *cqueue)
{
    if (cqueue->_.size == 0)
        return U_EEMPTY;

    cqueue->_.size -= cqueue->_.elem_size;
    cqueue->_.length--;

    U_CQUEUE_INCREMENT(_.begin);
    U_CQUEUE_INCREMENT(_.rend);

    U_CQUEUE_NORMALIZE(_.begin);
    U_CQUEUE_NORMALIZE(_.rend);

    return U_SUCCESS;
}

u_result_t u_cqueue_clear(struct u_cqueue *cqueue)
{
    cqueue->_.length = 0;

    cqueue->_.begin = 0;
    cqueue->_.rbegin = cqueue->_.block.size - cqueue->_.elem_size;

    cqueue->_.end = 0;
    cqueue->_.rend = cqueue->_.rbegin;
    
    cqueue->_.size = 0;

    return U_SUCCESS;
}

int u_cqueue_empty(struct u_cqueue *cqueue)
{
    return cqueue->_.size == 0;
}

int u_cqueue_full(struct u_cqueue *cqueue)
{
    return cqueue->_.size >= cqueue->_.block.size;
}

