#include <util/mem.h>
#include <util/cqueue.h>
#include <stdio.h>

void cqueue_print(struct u_cqueue *cqueue)
{
    printf("length = %zu\n", cqueue->_.length);
    printf("size = %zu\n", cqueue->_.size);

    printf("begin = %zu\n", cqueue->_.begin);
    printf("end = %zu\n", cqueue->_.end);
    printf("rbegin = %zu\n", cqueue->_.rbegin);
    printf("rend = %zu\n", cqueue->_.rend);

    for (int i = 0; i < cqueue->_.length; ++i)
    {
        printf("queue[%d] = %d\n", i, (int) *U_CQUEUE_AT(*cqueue, uint8_t, i));
        // printf("queue'[%d] = %d\n", i, (int) cqueue->_block.data[i]);
    }
}

int main()
{
    uint8_t num = 0;
    struct u_cqueue cqueue;

    u_cqueue_create(&cqueue, u_mem_malloc_allocator, sizeof(uint8_t), 4);

    num = 1;
    u_cqueue_pushfront(&cqueue, &num);

    num = 2;
    u_cqueue_pushback(&cqueue, &num);

    num = 3;
    u_cqueue_pushback(&cqueue, &num);

#if 1
    num = 4;
    u_cqueue_pushback(&cqueue, &num);


    u_cqueue_popfront(&cqueue);

    num = 8;
    u_cqueue_pushback(&cqueue, &num);
#endif

    printf("first = %d\n", (int) *U_CQUEUE_FIRST(cqueue, uint8_t));
    printf("last = %d\n", (int) *U_CQUEUE_LAST(cqueue, uint8_t));

    cqueue_print(&cqueue);

    u_cqueue_destroy(&cqueue);

    return 0;
}
