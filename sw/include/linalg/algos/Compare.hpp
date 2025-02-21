#ifndef LINALG_ALGOS_COMPARE_HPP_INCLUDED
#define LINALG_ALGOS_COMPARE_HPP_INCLUDED

#include <linalg/Defs.hpp>
#include <linalg/Exception.hpp>
#include <linalg/types/Dense.hpp>

#include <cmath>

#include <algorithm>
#include <type_traits>

#include <fmt/core.h>

namespace linalg::algos {

namespace detail {

template<class InputIt1, class InputIt2, typename Tolerance>
inline bool is_same(InputIt1 first1, InputIt1 last1, InputIt2 first2, Tolerance tolerance) {
    auto pred = [=](auto a, auto b) -> bool {
        auto diff = a - b;
        auto abs_diff = diff > 0 ? diff : -diff;

        if (abs_diff > tolerance) {
            fmt::print(
                "value A = {}, value B = {}, abs_diff = {}\n",
                a, b, abs_diff
            );

            return false;
        }

        return true;
    };

    return std::equal(first1, last1, first2, pred);
}

template<class InputIt1, class InputIt2, typename Tolerance>
inline bool is_same_relative(InputIt1 first1, InputIt1 last1, InputIt2 first2, Tolerance tolerance) {
#if 0
    auto pred = [=](auto a, auto b) -> bool {
        // TODO do this better!
        if (std::abs(a) < 1e-5) {
            if (std::abs(b) > 1e-5) {
                fmt::print(
                    "value A = {}, value B = {}\n",
                    a, b
                );
                return false;
            }
            return true;
        }

        auto diff = a - b;
        auto abs_diff = diff > 0 ? diff : -diff;
        double rel_diff = ((double)abs_diff) / ((double)std::abs(a));

        if (rel_diff > tolerance) {
            fmt::print(
                "value A = {}, value B = {}, abs_diff = {}, rel_diff = {}\n",
                a, b, abs_diff, rel_diff
            );

            return false;
        }

        return true;
    };

    return std::equal(first1, last1, first2, pred);
#endif
    auto pred = [=](auto a, auto b, int& mismatch_count) -> bool {
        bool is_equal = true;

        if (std::abs(a) < 1e-5) {
            if (std::abs(b) > 1e-5) {
                if (mismatch_count < 200) {
                    fmt::print(
                        "value A = {}, value B = {}\n",
                        a, b
                    );
                }
                is_equal = false;
                ++mismatch_count;
            }
        } else {
            auto diff = a - b;
            auto abs_diff = diff > 0 ? diff : -diff;
            double rel_diff = static_cast<double>(abs_diff) / static_cast<double>(std::abs(a));

            if (rel_diff > tolerance) {
                if (mismatch_count < 200) {
                    fmt::print(
                        "value A = {}, value B = {}, abs_diff = {}, rel_diff = {}\n",
                        a, b, abs_diff, rel_diff
                    );
                }
                is_equal = false;
                ++mismatch_count;
            }
        }

        return is_equal;
    };

    // Iterate over both ranges manually
    bool all_equal = true;
    int mismatch_count = 0;
    for (auto it1 = first1, it2 = first2; it1 != last1; ++it1, ++it2) {
        if (!pred(*it1, *it2, mismatch_count)) {
            all_equal = false;
        }
    }

    if (mismatch_count > 0) {
        fmt::print("total mismatches: {}\n", mismatch_count);
    }

    return all_equal;
}

template<typename T, typename U, typename Enable = void>
struct IsSame_Impl {
    template<typename Tolerance>
    static bool isSame(T const& t, U const& u, Tolerance tolerance) {
        LINALG_NOT_IMPLEMENTED;
    }

    template<typename Tolerance>
    static bool isSameRelative(T const& t, U const& u, Tolerance tolerance) {
        LINALG_NOT_IMPLEMENTED;
    }
};

template<
    typename DataTypeT_, StorageOrder StorageOrderT_,
    typename DataTypeU_, StorageOrder StorageOrderU_>
struct IsSame_Impl<
    types::DenseMatrix<DataTypeT_, StorageOrderT_>,
    types::DenseMatrix<DataTypeU_, StorageOrderU_>,
    void> {
    using T = types::DenseMatrix<DataTypeT_, StorageOrderT_>;
    using U = types::DenseMatrix<DataTypeU_, StorageOrderU_>;

    template<typename Tolerance>
    static bool isSame(T const& t, U const& u, Tolerance tolerance) {
        // later implement for other cases
        LINALG_REQUIRE(StorageOrderT_ == StorageOrderU_);

        if (t.numRows != u.numRows)
            return false;

        if (t.numCols != u.numCols)
            return false;

        auto data1 = t.data();
        auto data2 = t.data();

        size_t N = t.numRows * t.numCols;

        return is_same(data1, data1 + N, data2, tolerance);
    }

    template<typename Tolerance>
    static bool isSameRelative(T const& tExpected, U const& uObserved, Tolerance tolerance) {
        // later implement for other cases
        LINALG_REQUIRE(StorageOrderT_ == StorageOrderU_);

        if (tExpected.numRows != uObserved.numRows)
            return false;

        if (tExpected.numCols != uObserved.numCols)
            return false;

        auto data1 = tExpected.data();
        auto data2 = uObserved.data();

        size_t N = tExpected.numRows * tExpected.numCols;

        return is_same_relative(data1, data1 + N, data2, tolerance);
    }
};

template<
    typename DataTypeT_, typename IndexTypeT_, StorageOrder StorageOrderT_,
    typename DataTypeU_, typename IndexTypeU_, StorageOrder StorageOrderU_>
struct IsSame_Impl<
    types::CompressedSparseMatrix<DataTypeT_, IndexTypeT_, StorageOrderT_>,
    types::CompressedSparseMatrix<DataTypeU_, IndexTypeU_, StorageOrderU_>,
    void> {
    using T = types::CompressedSparseMatrix<DataTypeT_, IndexTypeT_, StorageOrderT_>;
    using U = types::CompressedSparseMatrix<DataTypeU_, IndexTypeU_, StorageOrderU_>;

    template<typename Tolerance>
    static bool isSame(T const& t, U const& u, Tolerance tolerance) {
        // later implement for other cases
        LINALG_REQUIRE(StorageOrderT_ == StorageOrderU_);

        if (t.numRows != u.numRows)
            return false;

        if (t.numCols != u.numCols)
            return false;

        if (t.numValues != u.numValues)
            return false;

        if (!is_same(t.values.begin(), t.values.end(), u.values.begin(), tolerance))
            return false;

        if (!is_same(t.indices.begin(), t.indices.end(), u.indices.begin(), 0))
            return false;

        if (!is_same(t.lengths.begin(), t.lengths.end(), u.lengths.begin(), 0))
            return false;

        return true;
    }

    template<typename Tolerance>
    static bool isSameRelative(T const& tExpected, U const& uObserved, Tolerance tolerance) {
        // later implement for other cases
        LINALG_REQUIRE(StorageOrderT_ == StorageOrderU_);

        if (tExpected.numRows != uObserved.numRows)
            return false;

        if (tExpected.numCols != uObserved.numCols)
            return false;

        if (tExpected.numRows != uObserved.numRows)
            return false;

        if (tExpected.numCols != uObserved.numCols)
            return false;

        if (tExpected.numValues != uObserved.numValues)
            return false;

        if (!is_same_relative(tExpected.values.begin(), tExpected.values.end(), uObserved.values.begin(), tolerance))
            return false;

        if (!is_same(tExpected.indices.begin(), tExpected.indices.end(), uObserved.indices.begin(), 0))
            return false;

        if (!is_same(tExpected.lengths.begin(), tExpected.lengths.end(), uObserved.lengths.begin(), 0))
            return false;

        return true;
    }
};

} // namespace detail

template<typename T, typename U, typename Tolerance>
inline bool isSame(T const& t, U const& u, Tolerance tolerance = 0) {
    return detail::IsSame_Impl<T, U>::isSame(t, u, tolerance);
}

template<typename T, typename U, typename Tolerance>
inline bool isSameRelative(T const& tExpected, U const& uObserved, Tolerance tolerance) {
    return detail::IsSame_Impl<T, U>::isSameRelative(tExpected, uObserved, tolerance);
}

} // namespace linalg::algos

#endif /* LINALG_ALGOS_COMPARE_HPP_INCLUDED */
