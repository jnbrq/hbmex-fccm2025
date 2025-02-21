#include <d4e/xil.h>
#include <error/error.h>

#include <stdio.h>
#include <stdlib.h>

#include <time.h>
#include <sys/time.h>

#include <sys/mman.h>

#define MAP_SZ (4ULL << 20)

/* Subtract timespec t2 from t1
 *
 * Both t1 and t2 must already be normalized
 * i.e. 0 <= nsec < 1000000000
 */
static int timespec_check(struct timespec *t)
{
    if ((t->tv_nsec < 0) || (t->tv_nsec >= 1000000000))
        return -1;
    return 0;
}

void timespec_sub(struct timespec *t1, struct timespec *t2)
{
    if (timespec_check(t1) < 0)
    {
        fprintf(stderr, "invalid time #1: %lld.%.9ld.\n",
                (long long)t1->tv_sec, t1->tv_nsec);
        return;
    }
    if (timespec_check(t2) < 0)
    {
        fprintf(stderr, "invalid time #2: %lld.%.9ld.\n",
                (long long)t2->tv_sec, t2->tv_nsec);
        return;
    }
    t1->tv_sec -= t2->tv_sec;
    t1->tv_nsec -= t2->tv_nsec;
    if (t1->tv_nsec >= 1000000000)
    {
        t1->tv_sec++;
        t1->tv_nsec -= 1000000000;
    }
    else if (t1->tv_nsec < 0)
    {
        t1->tv_sec--;
        t1->tv_nsec += 1000000000;
    }
}

#define KIBI (1ull << 10ull)
#define MEBI (1ull << 20ull)

struct test_params
{
    d4e_addr_t addr_fpga;
    struct d4e_device *device;
    char *buffer1;
    char *buffer2;

    uint64_t size_transfer;
    uint64_t num_transfers;
};

void rand_buffer(uint64_t sz, char *buffer)
{
    for (uint64_t i = 0; i < sz; ++i)
    {
        buffer[i] = (rand() % 256) - 128;
    }
}

/// @brief Compare two buffers.
/// @return 0 if the same, -1 if different
int comp_buffer(uint64_t sz, char *buffer1, char *buffer2)
{
    for (uint64_t i = 0; i < sz; ++i)
    {
        if (buffer1[i] != buffer2[i])
            return -1;
    }
    return 0;
}

static int test_correctness(struct test_params *t)
{
    printf("** %s **\n", __func__);

    for (uint64_t i = 0; i < 4; ++i)
    {
        rand_buffer(t->size_transfer, t->buffer1);
        E_ERR_IF_DIE(d4e_dma_h2d(t->device, t->addr_fpga, t->buffer1, t->size_transfer) != 0, "d4e_dma_h2d");
        E_ERR_IF_DIE(d4e_dma_d2h(t->device, t->buffer2, t->addr_fpga, t->size_transfer) != 0, "d4e_dma_d2h");

        if (comp_buffer(t->size_transfer, t->buffer1, t->buffer2) < 0)
        {
            printf("error: buffer mismatch.\n");
            return -1;
        }
    }

    printf("done.\n");

    return 0;
}

static int test_performance_h2c(struct test_params *t)
{
    printf("** %s **\n", __func__);
    uint64_t nsec = 0;
    struct timespec ts_start, ts_end;

    rand_buffer(t->size_transfer, t->buffer1);
    for (uint64_t i = 0; i < t->num_transfers; ++i)
    {
        clock_gettime(CLOCK_MONOTONIC, &ts_start);
        {
            E_ERR_IF_DIE(d4e_dma_h2d(t->device, t->addr_fpga, t->buffer1, t->size_transfer) != 0, "d4e_dma_h2d");
        }
        clock_gettime(CLOCK_MONOTONIC, &ts_end);
        timespec_sub(&ts_end, &ts_start);
        nsec += ts_end.tv_nsec;
    }

    double rate = ((double)t->num_transfers * (double)t->size_transfer / (double)MEBI) / ((double)nsec * (double)1e-9);
    printf("H2C transfer rate = %lf MiB/s\n", rate);
}

static int test_performance_c2h(struct test_params *t)
{
    printf("** %s **\n", __func__);
    uint64_t nsec = 0;
    struct timespec ts_start, ts_end;

    rand_buffer(t->size_transfer, t->buffer1);
    for (uint64_t i = 0; i < t->num_transfers; ++i)
    {
        clock_gettime(CLOCK_MONOTONIC, &ts_start);
        {
            E_ERR_IF_DIE(d4e_dma_d2h(t->device, t->buffer1, t->addr_fpga, t->size_transfer) != 0, "d4e_dma_d2h");
        }
        clock_gettime(CLOCK_MONOTONIC, &ts_end);
        timespec_sub(&ts_end, &ts_start);
        nsec += ts_end.tv_nsec;
    }

    double rate = ((double)t->num_transfers * (double)t->size_transfer / (double)MEBI) / ((double)nsec * (double)1e-9);
    printf("C2H transfer rate = %lf MiB/s\n", rate);
}

static int test_register(struct test_params *t)
{
    printf("** %s **\n", __func__);
    // also try out the registers
    d4e_reg_write32(t->device, 0, 0xDEAD);
    if (d4e_reg_read32(t->device, 0) != 0xDEAD)
        printf("register operations fail.\n");
    printf("done.\n");
    
    return 0;
}

#define MAP_HUGE_2MB    (21 << MAP_HUGE_SHIFT)
#define MAP_HUGE_1GB    (30 << MAP_HUGE_SHIFT)

int main()
{
    srand(time(0));

    struct timespec ts_start, ts_end;

    struct d4e_xil_device xil_device;
    if (d4e_xil_device_open(&xil_device, "/dev/xdma0", 0, 0, MAP_SZ) < 0)
        return EXIT_FAILURE;
    
    // Addresses for the FPGA
    // 
    //   0x0000000400000000ull for HBM
    //   0x000000000ull for the BRAM
    // 

    d4e_addr_t addr_fpga = 0x400000000ull;
    const uint64_t num_transfers = 1;
    const uint64_t size_transfer = 512 * MEBI;

    char *buffer1 = mmap(NULL, size_transfer, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS /* | MAP_HUGETLB | MAP_HUGE_2MB */, -1, 0);
    char *buffer2 = mmap(NULL, size_transfer, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS /* | MAP_HUGETLB | MAP_HUGE_2MB */, -1, 0);
    
    struct test_params tp = {
        .addr_fpga = addr_fpga,
        .device = &xil_device.device,
        .buffer1 = buffer1,
        .buffer2 = buffer2,
        .size_transfer = size_transfer,
        .num_transfers = num_transfers
    };

    d4e_reg_write32(&xil_device.device, 0x100000, 0xDEAD);

    test_correctness(&tp);
    test_performance_h2c(&tp);
    test_performance_c2h(&tp);
    test_register(&tp);

    munmap(buffer1, size_transfer);
    munmap(buffer2, size_transfer);

    d4e_close(&xil_device.device);

    return 0;
}
