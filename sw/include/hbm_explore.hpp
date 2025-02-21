#ifndef hbm_explore_hpp_INCLUDED
#define hbm_explore_hpp_INCLUDED

#include <cstdint>

#include <memory>
#include <sstream>
#include <vector>

#include <fmt/core.h>

struct index_tag {};
struct literal_tag {};

struct IndexOrLiteral {
    constexpr IndexOrLiteral(literal_tag, bool b)
        : isIndex_ { false }
        , index_ { b } {
    }

    constexpr IndexOrLiteral(index_tag, std::uint32_t index)
        : isIndex_ { true }
        , index_ { index } {
    }

    constexpr IndexOrLiteral(std::uint32_t index)
        : IndexOrLiteral { index_tag {}, index } {
    }

    constexpr bool isIndex() const noexcept { return isIndex_; }
    constexpr bool isLiteral() const noexcept { return !isIndex_; }

    constexpr bool literalValue() const noexcept { return index_; }
    constexpr std::uint32_t indexValue() const noexcept { return index_; }

    std::string toString() const {
        if (isIndex()) {
            return fmt::format("{}", indexValue());
        } else {
            return fmt::format("{}_", literalValue());
        }
    }

private:
    bool isIndex_;
    std::uint32_t index_;
};

static constexpr auto false_ = IndexOrLiteral { literal_tag {}, false };
static constexpr auto true_ = IndexOrLiteral { literal_tag {}, true };

struct Transform : std::enable_shared_from_this<Transform> {
    virtual const char* toString() const noexcept = 0;
    virtual std::uint64_t transform(std::uint64_t addr) const = 0;

    static std::shared_ptr<Transform> mkIdentity();
    static std::shared_ptr<Transform> mkShiftLeft(unsigned shiftCount);

    template<typename Iterator>
    static std::shared_ptr<Transform> mkGeneric(Iterator a, Iterator b);

    static std::shared_ptr<Transform> mkGenericLE(std::vector<IndexOrLiteral> const& l) {
        return mkGeneric(l.begin(), l.end());
    }

    static std::shared_ptr<Transform> mkGenericBE(std::vector<IndexOrLiteral> const& l) {
        return mkGeneric(l.rbegin(), l.rend());
    }

    std::shared_ptr<Transform> then(std::shared_ptr<Transform> next);
};

namespace detail {

struct IdentityTransform : Transform {
    const char* toString() const noexcept override {
        return "IdentityTransform";
    }

    std::uint64_t transform(std::uint64_t addr) const override {
        return addr;
    }
};

struct ShiftLeftTransform : Transform {
    ShiftLeftTransform(unsigned shiftCount)
        : shiftCount_ { shiftCount }
        , string_ { fmt::format("ShiftTransform(shiftCount = {})", shiftCount) } {
    }

    const char* toString() const noexcept override {
        return string_.c_str();
    }

    std::uint64_t transform(std::uint64_t addr) const override {
        return addr << shiftCount_;
    }

private:
    unsigned shiftCount_ = 0;
    std::string string_;
};

struct GenericTransform : Transform {
    GenericTransform(std::vector<IndexOrLiteral> vec)
        : vec_ { std::move(vec) } {
        std::ostringstream oss;
        oss << "GenericTransform(vec = [";

        for (std::uint32_t idx = 0; idx < vec_.size(); ++idx) {
            oss << vec_[idx].toString();

            if (idx != (vec_.size() - 1))
                oss << ", ";
        }

        oss << "])";

        string_ = oss.str();
    }

    const char* toString() const noexcept override {
        return string_.c_str();
    }

    std::uint64_t transform(std::uint64_t addr) const override {
        return impl(addr, vec_.begin(), vec_.end());
    }

private:
    std::vector<IndexOrLiteral> vec_;
    std::string string_;

    static std::uint64_t impl(
        std::uint64_t addr,
        std::vector<IndexOrLiteral>::const_iterator a,
        std::vector<IndexOrLiteral>::const_iterator b
    ) {
        std::uint64_t result = 0;
        std::uint32_t index = 0;

        while (a != b) {
            IndexOrLiteral x = *a;

            if (x.isLiteral()) {
                result = result | (((std::uint64_t)x.literalValue()) << index);
            } else {
                result = result | (((std::uint64_t)((addr >> x.indexValue()) & 1)) << index);
            }

            ++a;
            ++index;
        }

        return result;
    }
};

struct ComposedTransform : Transform {
    ComposedTransform(std::shared_ptr<Transform> first, std::shared_ptr<Transform> second)
        : first_ { first }
        , second_ { second }
        , string_ { fmt::format("ComposedTransform(first = {}, second = {})", first->toString(), second->toString()) } {
    }

    const char* toString() const noexcept override {
        return string_.c_str();
    }

    std::uint64_t transform(std::uint64_t addr) const override {
        return second_->transform(first_->transform(addr));
    }

private:
    std::shared_ptr<Transform> first_, second_;
    std::string string_;
};

} // namespace detail

inline std::shared_ptr<Transform> Transform::mkIdentity() {
    static auto ptr = std::make_shared<detail::IdentityTransform>();
    return ptr;
}

inline std::shared_ptr<Transform> Transform::mkShiftLeft(unsigned shiftCount) {
    return std::make_shared<detail::ShiftLeftTransform>(shiftCount);
}

template<typename Iterator>
inline std::shared_ptr<Transform> Transform::mkGeneric(Iterator a, Iterator b) {
    // TODO somehow check and make sure that the iterator value_type is correct
    return std::make_shared<detail::GenericTransform>(std::vector<IndexOrLiteral>(a, b));
}

inline std::shared_ptr<Transform> Transform::then(std::shared_ptr<Transform> next) {
    return std::make_shared<detail::ComposedTransform>(shared_from_this(), next);
}

enum class IdMode {
    ID_ZERO,
    ID_MASK_INDEX,
    ID_SHIFT_MASK_ADDR
};

struct DataPointConfig {
    IdMode idMode;
    uint16_t idShift;
    uint16_t len;

    // the number of bits to be generated randomly
    uint16_t rndAddrBits;

    // the address is applied with this transformation undex
    std::shared_ptr<Transform> transform;

    std::string extra;

    std::string toString() const {
        // convert this to string using fmt::format
        // please expand the following line
        // do not forget to have transforms[transformIndex]->name()

        std::string idModeStr;
        switch (idMode) {
        case IdMode::ID_ZERO:
            idModeStr = "ID_ZERO";
            break;
        case IdMode::ID_MASK_INDEX:
            idModeStr = "ID_MASK_INDEX";
            break;
        case IdMode::ID_SHIFT_MASK_ADDR:
            idModeStr = "ID_SHIFT_MASK_ADDR";
            break;
        }

        return fmt::format(
            "idMode = {}, idShift = {}, len = {}, rndAddrBits = {}, transformString = {}, extra = '{}'",
            idModeStr, idShift, len, rndAddrBits,
            transform->toString(), extra
        );
    }
};

#endif // hbm_explore_hpp_INCLUDED
