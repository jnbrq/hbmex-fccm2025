#ifndef LINALG_EXCHANGE_MATRIXMARKET_HPP_INCLUDED
#define LINALG_EXCHANGE_MATRIXMARKET_HPP_INCLUDED

#include <linalg/Defs.hpp>
#include <linalg/Exception.hpp>
#include <linalg/types/Dense.hpp>
#include <linalg/types/Sparse.hpp>

#include <algorithm>
#include <ios>
#include <sstream>

namespace linalg::exchange {

namespace matrix_market {

struct TypeCode {
    char c0 { 'G' };
    char c1 { ' ' };
    char c2 { ' ' };
    char c3 { ' ' };

    bool isMatrix() const noexcept { return c0 == 'M'; }
    bool isSparse() const noexcept { return c1 == 'C'; }
    bool isDense() const noexcept { return c1 == 'A'; }
    bool isCoordinate() const noexcept { return isSparse(); }
    bool isArray() const noexcept { return isDense(); }

    bool isComplex() const noexcept { return c2 == 'C'; }
    bool isReal() const noexcept { return c2 == 'R'; }
    bool isPattern() const noexcept { return c2 == 'P'; }
    bool isInteger() const noexcept { return c2 == 'I'; }

    bool isSymmetric() const noexcept { return c3 == 'S'; }
    bool isGeneral() const noexcept { return c3 == 'G'; }
    bool isSkew() const noexcept { return c3 == 'K'; }
    bool isHermitian() const noexcept { return c3 == 'H'; }

    void setMatrix() noexcept { c0 = 'M'; }
    void setSparse() noexcept { c1 = 'C'; }
    void setDense() noexcept { c1 = 'A'; }
    void setCoordinate() noexcept { setSparse(); }
    void setArray() noexcept { setDense(); }

    void setComplex() noexcept { c2 = 'C'; }
    void setReal() noexcept { c2 = 'R'; }
    void setPattern() noexcept { c2 = 'P'; }
    void setInteger() noexcept { c2 = 'I'; }

    void setSymmetric() noexcept { c3 = 'S'; }
    void setGeneral() noexcept { c3 = 'G'; }
    void setSkew() noexcept { c3 = 'K'; }
    void setHermitian() noexcept { c3 = 'H'; }

    void clearTypeCode() noexcept {
        c0 = ' ';
        c1 = ' ';
        c2 = ' ';
        c3 = 'G';
    }

    void initializeTypeCode() noexcept {
        clearTypeCode();
    }

    bool isValid() const noexcept {
        return isMatrix();
    }

    std::string toString() const {
        std::ostringstream oss;

        oss << "TypeCode(";
        oss << "Matrix: " << (isMatrix() ? "Yes" : "No") << ", ";
        oss << "Sparse: " << (isSparse() ? "Yes" : "No") << ", ";
        oss << "Dense: " << (isDense() ? "Yes" : "No") << ", ";
        oss << "Complex: " << (isComplex() ? "Yes" : "No") << ", ";
        oss << "Real: " << (isReal() ? "Yes" : "No") << ", ";
        oss << "Pattern: " << (isPattern() ? "Yes" : "No") << ", ";
        oss << "Integer: " << (isInteger() ? "Yes" : "No") << ", ";
        oss << "Symmetric: " << (isSymmetric() ? "Yes" : "No") << ", ";
        oss << "General: " << (isGeneral() ? "Yes" : "No") << ", ";
        oss << "Skew: " << (isSkew() ? "Yes" : "No") << ", ";
        oss << "Hermitian: " << (isHermitian() ? "Yes" : "No") << ")";

        return oss.str();
    }
};

struct Dimensions {
    size_t numRows;
    size_t numCols;
    size_t numValues;

    std::string toString() const {
        std::ostringstream oss;

        oss << "Dimensions(";
        oss << "Rows: " << numRows << ", ";
        oss << "Cols: " << numCols << ", ";
        oss << "Values: " << numValues;
        oss << ")";

        return oss.str();
    }
};

struct InputStream {
    InputStream(std::istream& ifs)
        : is_ { ifs } {
    }

    void parseMetadata() {
        if (metadataProcessed_)
            throw Exception("MM_METADATA_ALREADY_PROCESSED");

        processMetadata_();
        metadataProcessed_ = true;
    }

    const char* comments() const noexcept {
        return comments_.c_str();
    }

    TypeCode typeCode() const noexcept {
        return typeCode_;
    }

    Dimensions dimensions() const noexcept {
        return dimensions_;
    }

    template<typename DataType_, StorageOrder StorageOrder_>
    types::DenseMatrix<DataType_, StorageOrder_> loadDenseMatrix() {
        throw Exception("MM_NOT_IMPLEMENTED");
    }

    template<typename SparseMatrix>
    void loadSparseMatrix(SparseMatrix& spm) {
        bool cond = typeCode_.isMatrix() && typeCode_.isSparse() && (typeCode_.isReal() || typeCode_.isPattern());

        if (!cond)
            throw Exception("MM_SPARSE_ERROR");

        size_t numProcessed = 0;
        std::string line;

        while (std::getline(is_, line)) {
            if (line.empty())
                continue;

            numProcessed++;

            std::istringstream iss(line);

            if (typeCode_.isReal()) {
                size_t i, j;
                real_t v;

                if (!(iss >> i >> j >> v))
                    throw Exception("MM_SPARSE_BAD_VALUE");

                spm.set(i - 1, j - 1, v);

                if (typeCode_.isSymmetric()) {
                    spm.set(j - 1, i - 1, v);
                }
            } else {
                LINALG_REQUIRE(typeCode_.isPattern());

                size_t i, j;
                if (!(iss >> i >> j))
                    throw Exception("MM_SPARSE_BAD_VALUE");

                spm.set(i - 1, j - 1, 1);

                if (typeCode_.isSymmetric()) {
                    spm.set(j - 1, i - 1, 1);
                }
            }
        }

        if (numProcessed != dimensions_.numValues)
            throw Exception("MM_SPARSE_UNEXPECTED_NUMBER_OF_VALUES");
    }

    template<typename SparseMatrix>
    SparseMatrix loadSparseMatrix() {
        SparseMatrix spm(dimensions_.numRows, dimensions_.numCols);
        loadSparseMatrix(spm);

        return spm;
    }

private:
    std::istream& is_;
    bool metadataProcessed_ { false };

    TypeCode typeCode_;
    std::string comments_;
    Dimensions dimensions_;

    void processMetadata_() {
        std::string line;

        // process headers
        {
            constexpr const char* MatrixMarketBanner = "%%MatrixMarket";
            constexpr const char* MM_MTX_STR = "matrix";
            constexpr const char* MM_SPARSE_STR = "coordinate";
            constexpr const char* MM_DENSE_STR = "array";
            constexpr const char* MM_REAL_STR = "real";
            constexpr const char* MM_COMPLEX_STR = "complex";
            constexpr const char* MM_PATTERN_STR = "pattern";
            constexpr const char* MM_INT_STR = "integer";
            constexpr const char* MM_GENERAL_STR = "general";
            constexpr const char* MM_SYMM_STR = "symmetric";
            constexpr const char* MM_HERM_STR = "hermitian";
            constexpr const char* MM_SKEW_STR = "skew";

            std::string banner, mtx, crd, dataType, storageScheme;

            typeCode_.clearTypeCode();

            if (!std::getline(is_, line))
                throw Exception("MM_PREMATURE_EOF");

            std::istringstream iss(line);
            if (!(iss >> banner >> mtx >> crd >> dataType >> storageScheme))
                throw Exception("MM_PREMATURE_EOF");

            auto toLower = [](std::string& str) {
                std::transform(str.begin(), str.end(), str.begin(), [](unsigned char c) { return std::tolower(c); });
            };

            toLower(mtx);
            toLower(crd);
            toLower(dataType);
            toLower(storageScheme);

            if (banner != MatrixMarketBanner)
                throw Exception("MM_NO_HEADER");

            if (mtx != MM_MTX_STR)
                throw Exception("MM_UNSUPPORTED_TYPE");
            typeCode_.setMatrix();

            if (crd == MM_SPARSE_STR) {
                typeCode_.setSparse();
            } else if (crd == MM_DENSE_STR) {
                typeCode_.setDense();
            } else
                throw Exception("MM_UNSUPPORTED_KIND");

            if (dataType == MM_REAL_STR) {
                typeCode_.setReal();
            } else if (dataType == MM_COMPLEX_STR) {
                typeCode_.setComplex();
            } else if (dataType == MM_PATTERN_STR) {
                typeCode_.setPattern();
            } else if (dataType == MM_INT_STR) {
                typeCode_.setInteger();
            } else
                throw Exception("MM_UNSUPPORTED_DATATYPE");

            if (storageScheme == MM_GENERAL_STR) {
                typeCode_.setGeneral();
            } else if (storageScheme == MM_SYMM_STR) {
                typeCode_.setSymmetric();
            } else if (storageScheme == MM_HERM_STR) {
                typeCode_.setHermitian();
            } else if (storageScheme == MM_SKEW_STR) {
                typeCode_.setSkew();
            } else
                throw Exception("MM_UNSUPPORTED_STORAGE");
        }

        // process comments
        {
            std::ostringstream oss;
            int numItemsRead = 0;

            while (std::getline(is_, line)) {
                if (!line.empty()) {
                    if (line[0] == '%') {
                        oss << line << '\n';
                    } else
                        break;
                }
            }

            comments_ = oss.str();
        }

        // process dimensions
        {
            if (is_.eof())
                throw Exception("MM_PREMATURE_EOF");

            do {
                std::istringstream iss(line);
                if (iss >> dimensions_.numRows >> dimensions_.numCols >> dimensions_.numValues) {
                    return;
                }

            } while (!is_.eof());

            throw Exception("MM_PREMATURE_EOF");
        }
    }
};

} // namespace matrix_market

} // namespace linalg::exchange

#endif /* LINALG_EXCHANGE_MATRIXMARKET_HPP_INCLUDED */
