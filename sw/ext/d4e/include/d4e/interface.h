#ifndef D4E_INTERFACE_H_INCLUDED
#define D4E_INTERFACE_H_INCLUDED

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C"
{
#endif

typedef uint64_t d4e_addr_t;

#define D4E_SUCCESS     (0)
#define D4E_ERROR       (-1)
#define D4E_STOPPED     (-2)

/**
 * @brief Defines a vendor-agnostic interface to a device.
 *
 */
struct d4e_device
{
    int (*interrupt_open)(struct d4e_device *device, uint64_t interrupt_id);
    int (*interrupt_close)(struct d4e_device *device, int fd);
    int (*interrupt_ack)(struct d4e_device *device, int fd);
    int (*interrupt_wait)(struct d4e_device *device, int fd);

    int (*dma_h2d)(struct d4e_device *device, d4e_addr_t dest, void const *src, size_t size);
    int (*dma_d2h)(struct d4e_device *device, void *dest, d4e_addr_t src, size_t size);

    uint32_t (*reg_read32)(struct d4e_device *device, d4e_addr_t addr);
    uint64_t (*reg_read64)(struct d4e_device *device, d4e_addr_t addr);
    void (*reg_write32)(struct d4e_device *device, d4e_addr_t addr, uint32_t value);
    void (*reg_write64)(struct d4e_device *device, d4e_addr_t addr, uint64_t value);

    int (*close)(struct d4e_device *device);
};

/**
 * @brief Opens an interrupt.
 *
 * @param device
 * @param interrupt_id
 * @return int File descriptor to the interrupt, -1 in case of error.
 */
int d4e_interrupt_open(struct d4e_device *device, uint64_t interrupt_id);

/**
 * @brief Closes an interrupt file descriptor.
 *
 * @param device
 * @param fd
 * @return int 0 if success, -1 in case of error.
 */
int d4e_interrupt_close(struct d4e_device *device, int fd);

/**
 * @brief Acknowledges an interrupt.
 * @note Call after polling.
 * @note MT-safe for distinct file descriptors.
 *
 * @param device
 * @param fd
 * @return int 0 if success, -1 in case of error.
 */
int d4e_interrupt_ack(struct d4e_device *device, int fd);

/**
 * @brief Waits for an interrupt.
 * @note MT-safe for distinct file descriptors.
 *
 * @param device
 * @param fd
 * @return int 0 if success, -1 in case of error.
 */
int d4e_interrupt_wait(struct d4e_device *device, int fd);

/**
 * @brief Waits for an interrupt. Can be interruptable with a stop file descriptor.
 * @note MT-safe for distinct file descriptors.
 *
 * @param device
 * @param fd
 * @param efd_stop
 * @return int 0 if success, -1 in case of error, -2 if stopped.
 */
int d4e_interrupt_wait2(struct d4e_device *device, int fd, int efd_stop);

/**
 * @brief Performs a DMA transfer from device to host.
 * @note MT-safe.
 *
 * @param device
 * @param dest
 * @param src
 * @return int 0 if success, -1 in case of error.
 */
int d4e_dma_d2h(struct d4e_device *device, void *dest, d4e_addr_t src, size_t size);

/**
 * @brief Performs a DMA transfer from host to device.
 * @note MT-safe.
 *
 * @param device
 * @param dest
 * @param src
 * @return int 0 if success, -1 in case of error.
 */
int d4e_dma_h2d(struct d4e_device *device, d4e_addr_t dest, void const *src, size_t size);

/**
 * @brief Reads from a 32-bit register.
 * @note MT-safe for distinct registers.
 *
 * @param device
 * @param addr
 * @return uint32_t Register value.
 */
uint32_t d4e_reg_read32(struct d4e_device *device, d4e_addr_t addr);

/**
 * @brief Reads from a 64-bit register.
 * @note MT-safe for distinct registers.
 *
 * @param device
 * @param addr
 * @return uint64_t Register value.
 */
uint64_t d4e_reg_read64(struct d4e_device *device, d4e_addr_t addr);

/**
 * @brief Writes to a 32-bit register.
 * @note MT-safe for distinct registers.
 *
 * @param device
 * @param addr
 * @param value
 */
void d4e_reg_write32(struct d4e_device *device, d4e_addr_t addr, uint32_t value);

/**
 * @brief Writes to a 64-bit register.
 * @note MT-safe for distinct registers.
 *
 * @param device
 * @param addr
 * @param value
 */
void d4e_reg_write64(struct d4e_device *device, d4e_addr_t addr, uint64_t value);

/**
 * @brief Closes the device.
 *
 * @param device
 * @return int 0 if success, -1 in case of error.
 */
int d4e_close(struct d4e_device *device);

#ifdef __cplusplus
}
#endif

#endif /* D4E_INTERFACE_H_INCLUDED */
