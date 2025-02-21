#ifndef HAL_D4E_HPP_INCLUDED
#define HAL_D4E_HPP_INCLUDED

#include <d4e/interface.h>
#include <hal/hal.hpp>

#include <memory>

namespace d4e {

std::shared_ptr<hal::Sleep> sleep();
std::shared_ptr<hal::Memory> wrapDevice(d4e_device *dev);

} // namespace d4e

#endif // HAL_D4E_HPP_INCLUDED
