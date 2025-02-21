#ifndef LINALG_EXCEPTION_HPP_INCLUDED
#define LINALG_EXCEPTION_HPP_INCLUDED

#include <stdexcept>
#include <string>

namespace linalg {

class Exception : public std::exception {
private:
    std::string explanation_;

public:
    explicit Exception(const std::string& explanation)
        : explanation_(explanation) {}

    const char* what() const noexcept override {
        return explanation_.c_str();
    }
};

} // namespace linalg

#define LINALG_NOT_IMPLEMENTED                                                    \
    do {                                                                          \
        throw Exception(fmt::format("Not implemented: {}", __PRETTY_FUNCTION__)); \
    } while (0)

#ifndef NDEBUG

#    define LINALG_REQUIRE(x)                                         \
        do {                                                          \
            if (!(x))                                                 \
                throw ::linalg::Exception("Requirement failed: " #x); \
        } while (0)

#    define LINALG_ASSERT(x)                                        \
        do {                                                        \
            if (!(x))                                               \
                throw ::linalg::Exception("Assertion failed: " #x); \
        } while (0)

#    define LINALG_NOEXCEPT

#else

#    define LINALG_REQUIRE(x)
#    define LINALG_ASSERT(x)
#    define LINALG_NOEXCEPT noexcept

#endif

#endif /* LINALG_EXCEPTION_HPP_INCLUDED */
