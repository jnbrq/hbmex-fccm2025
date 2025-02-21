#ifndef CHEXT_TEST_UTIL_BOOLWRAPPER_HPP_INCLUDED
#define CHEXT_TEST_UTIL_BOOLWRAPPER_HPP_INCLUDED

namespace chext_test::util {

template<bool Invert, typename T>
struct BoolWrapper {
    BoolWrapper(T& t)
        : t_ { t } {}

    T* operator->() {
        return &t_;
    }

    T const* operator->() const {
        return &t_;
    }

    const auto& posedge_event() const {
        if constexpr (!Invert)
            return t_.posedge_event();
        else
            return t_.negedge_event();
    }

    const auto& negedge_event() const {
        if constexpr (!Invert)
            return t_.negedge_event();
        else
            return t_.posedge_event();
    }

    auto read() const {
        if constexpr (!Invert)
            return t_.read();
        else
            return !t_.read();
    }

    void write(bool b) {
        if constexpr (!Invert)
            t_.write(b);
        else
            t_.write(!b);
    }

private:
    T& t_;
};

template<bool Invert, typename T>
struct ConstBoolWrapper {
    ConstBoolWrapper(T const& t)
        : t_ { t } {}

    T const* operator->() const {
        return &t_;
    }

    const auto& posedge_event() const {
        if constexpr (!Invert)
            return t_.posedge_event();
        else
            return t_.negedge_event();
    }

    const auto& negedge_event() const {
        if constexpr (!Invert)
            return t_.negedge_event();
        else
            return t_.posedge_event();
    }

    auto read() const {
        if constexpr (!Invert)
            return t_.read();
        else
            return !t_.read();
    }

private:
    T const& t_;
};

template<bool Invert, typename T>
inline auto boolWrapper(T& t) {
    return BoolWrapper<Invert, T>(t);
}

template<bool Invert, typename T>
inline auto constBoolWrapper(T const& t) {
    return ConstBoolWrapper<Invert, T>(t);
}

} // namespace chext_test::util

#endif /* CHEXT_TEST_UTIL_BOOLWRAPPER_HPP_INCLUDED */
