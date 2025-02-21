#ifndef CHEXT_TEST_UTIL_EXCEPTION_HPP_INCLUDED
#define CHEXT_TEST_UTIL_EXCEPTION_HPP_INCLUDED

#include <exception>
#include <string>

namespace chext_test::util {

struct Exception : std::exception {
    Exception(std::string msg)
        : msg_ { std::move(msg) } {
    }

    const char* what() const noexcept {
        return msg_.c_str();
    }

private:
    std::string msg_;
};

} // namespace chext_test::util

#endif /* CHEXT_TEST_UTIL_EXCEPTION_HPP_INCLUDED */
