#include <util/mem.h>
#include <assert.h>

#define MEM_SZ (4096)

char mem[MEM_SZ];
struct u_mem_linear_allocator linear_allocator;

int main()
{
    u_result_t res;

    u_mem_linear_allocator_init(&linear_allocator, mem, MEM_SZ);
    struct u_mem_allocator *alloc = &linear_allocator.allocator;

    struct u_mem_block block;

    res = u_mem_alloc(alloc, &block, 256);
    assert(res == U_SUCCESS);
    assert(block.data == mem);
    assert(block.size == 256);

    u_mem_free(alloc, &block);
    
    res = u_mem_alloc(alloc, &block, 256);
    assert(res == U_SUCCESS);
    assert(block.data == mem);
    assert(block.size == 256);

    u_mem_free(alloc, &block);
    
    res = u_mem_alloc(alloc, &block, MEM_SZ);
    assert(res == U_SUCCESS);
    assert(block.data == mem);
    assert(block.size == MEM_SZ);

    struct u_mem_block block2;
    u_mem_block_init(&block2);

    res = u_mem_alloc(alloc, &block2, 1);
    assert(res == U_FAILURE);
    assert(block2.data == NULL);
    assert(block2.size == 0);

    u_mem_free(alloc, &block);

    res = u_mem_alloc(alloc, &block, 256);
    assert(res == U_SUCCESS);
    assert(block.data == mem);
    assert(block.size == 256);

    res = u_mem_alloc(alloc, &block2, 256);
    assert(res == U_SUCCESS);
    assert(block2.data == block.data + 256);
    assert(block2.size == 256);

    return 0;
}
