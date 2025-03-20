#ifndef JQR_INSPECT_HPP_INCLUDED
#define JQR_INSPECT_HPP_INCLUDED

#include <type_traits>

#define JQR_DEFINE_INSPECT(name, expr)                               \
    template<typename T, typename Enable = void>                     \
    struct name : std::false_type {};                                \
                                                                     \
    template<typename T>                                             \
    struct name<T, std::void_t<decltype(expr)>> : std::true_type {}; \
                                                                     \
    template<typename T>                                             \
    constexpr bool name##_v = name<T>::value;

#endif /* JQR_INSPECT_HPP_INCLUDED */
