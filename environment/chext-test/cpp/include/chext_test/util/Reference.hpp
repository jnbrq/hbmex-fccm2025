#ifndef CHEXT_TEST_UTIL_REFERENCE_HPP_INCLUDED
#define CHEXT_TEST_UTIL_REFERENCE_HPP_INCLUDED

#include <stdexcept>
#include <typeinfo>

namespace chext_test::util {

struct Reference;
struct ConstReference;

struct Reference {
    Reference(std::type_info const& typeInfo, void* ptr)
        : typeInfo_ { typeInfo }
        , ptr_ { ptr } {
    }

    template<typename T>
    Reference(T& t)
        : Reference(typeid(T), (void*)&t) {
    }

    Reference(Reference const&) = default;
    Reference(Reference&&) = default;

    Reference& operator=(Reference const&) = delete;
    Reference& operator=(Reference&&) = delete;

    template<typename T>
    bool is() const { return typeid(T) == typeInfo_; }

    template<typename T>
    T& get() {
        if (!is<T>())
            throw std::bad_cast();

        return *((T*)ptr_);
    }

    template<typename T>
    T const& get() const {
        if (!is<T>())
            throw std::bad_cast();

        return *((T const*)ptr_);
    }

    ConstReference asConst() const;

    ~Reference() = default;

private:
    std::type_info const& typeInfo_;
    void* ptr_;
};

struct ConstReference {
    ConstReference(std::type_info const& typeInfo, void const* ptr)
        : typeInfo_ { typeInfo }
        , ptr_ { ptr } {
    }

    template<typename T>
    ConstReference(T const& t)
        : ConstReference(typeid(T), (void const*)&t) {
    }

    ConstReference(ConstReference const&) = default;
    ConstReference(ConstReference&&) = default;

    ConstReference& operator=(ConstReference const&) = delete;
    ConstReference& operator=(ConstReference&&) = delete;

    template<typename T>
    bool is() const { return typeid(T) == typeInfo_; }

    template<typename T>
    T const& get() const {
        if (!is<T>())
            throw std::bad_cast();

        return *((T const*)ptr_);
    }

    ~ConstReference() = default;

private:
    std::type_info const& typeInfo_;
    void const* ptr_;
};

inline ConstReference Reference::asConst() const {
    return ConstReference(typeInfo_, ptr_);
}

} // namespace chext_test::util

#endif /* CHEXT_TEST_UTIL_REFERENCE_HPP_INCLUDED */
