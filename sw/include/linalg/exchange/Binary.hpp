#ifndef LINALG_EXCHANGE_BINARY_HPP_INCLUDED
#define LINALG_EXCHANGE_BINARY_HPP_INCLUDED

#include <boost/endian.hpp>

#include <linalg/Defs.hpp>
#include <linalg/Exception.hpp>
#include <linalg/types/CompressedSparse.hpp>

#include <cstring>

namespace linalg::exchange::binary {

namespace detail {

struct BinaryReader {
    BinaryReader(const byte_t* ptr, size_t size)
        : ptr_ { ptr }
        , size_ { size } {}

    template<typename T>
    void read(T& t) {
        read(&t, sizeof(T));
    }

    template<typename T, unsigned N>
    void readArray(T (&arr)[N]) {
        read(arr, N * sizeof(T));
    }

    template<typename T, typename Allocator>
    void readStdVector(std::vector<T, Allocator>& vec) {
        read(vec.data(), sizeof(T) * vec.size());
    }

    void read(void* dest, size_t size) {
        if (size_ < size)
            throw Exception("premature end of binary data!");

        std::memcpy(dest, ptr_, size);
        size_ -= size;
        ptr_ += size;
    }

    void end() {
        if (size_ != 0)
            throw std::runtime_error("binary data not consumed entirely!");
    }

private:
    const byte_t* ptr_;
    size_t size_;
};

struct BinaryWriter {
    BinaryWriter(byte_t* ptr, size_t size)
        : ptr_ { ptr }
        , size_ { size } {}

    template<typename T>
    void write(T const& t) {
        write(&t, sizeof(T));
    }

    template<typename T, unsigned N>
    void writeArray(const T (&arr)[N]) {
        write(arr, N * sizeof(T));
    }

    template<typename T, typename Allocator>
    void writeStdVector(std::vector<T, Allocator> const& vec) {
        write(vec.data(), sizeof(T) * vec.size());
    }

    void write(void const* src, size_t size) {
        if (size_ < size)
            throw Exception("premature end of bufferi!");

        std::memcpy(ptr_, src, size);
        size_ -= size;
        ptr_ += size;
    }

    void end() {
        if (size_ != 0)
            throw Exception("binary data not produced entirely!");
    }

private:
    byte_t* ptr_;
    size_t size_;
};

template<typename T, typename Enable = void>
struct Impl {
    static T load(byte_t const* data, size_t size) {
        LINALG_NOT_IMPLEMENTED;
    }

    static void save(T const& t, byte_t*& data, size_t& size) {
        LINALG_NOT_IMPLEMENTED;
    }
};

template<typename DataType_, typename IndexType_, StorageOrder StorageOrder_>
struct Impl<types::CompressedSparseMatrix<DataType_, IndexType_, StorageOrder_>, void> {
    using T = types::CompressedSparseMatrix<DataType_, IndexType_, StorageOrder_>;

    static T load(byte_t const* data, size_t size) {
        using big_size_at = boost::endian::big_uint64_at;

        BinaryReader reader(data, size);

        big_size_at numCols, numRows, numValues;

        reader.read(numCols);
        reader.read(numRows);
        reader.read(numValues);

        std::vector<DataType_> values(numValues);
        std::vector<IndexType_> indices(numValues);
        std::vector<IndexType_> lengths(StorageOrder_ == RowMajor ? numRows : numCols);

        reader.readStdVector(values);
        reader.readStdVector(indices);
        reader.readStdVector(lengths);

        reader.end();

        return {
            numRows,
            numCols,
            numValues,
            std::move(values),
            std::move(indices),
            std::move(lengths)
        };
    }

    static void save(T const& t, byte_t*& data, size_t& size) {
        using big_size_at = boost::endian::big_uint64_at;

        size = //
            sizeof(big_size_at) * 3 + //
            sizeof(DataType_) * t.numValues + //
            sizeof(IndexType_) * t.numValues + //
            sizeof(IndexType_) * (StorageOrder_ == RowMajor ? t.numRows : t.numCols);

        std::unique_ptr<byte_t[]> buffer { new byte_t[size] };

        BinaryWriter writer(buffer.get(), size);

        writer.write(big_size_at(t.numCols));
        writer.write(big_size_at(t.numRows));
        writer.write(big_size_at(t.numValues));

        writer.writeStdVector(t.values);
        writer.writeStdVector(t.indices);
        writer.writeStdVector(t.lengths);

        writer.end();

        data = buffer.get();
        buffer.release();
    }
};

}; // namespace detail

template<typename T>
inline T load(byte_t const* data, size_t size) {
    return detail::Impl<T>::load(data, size);
}

template<typename T>
inline void save(T const& t, byte_t*& data, size_t& size) {
    return detail::Impl<T>::save(t, data, size);
}

} // namespace linalg::exchange::binary

#endif /* LINALG_EXCHANGE_BINARY_HPP_INCLUDED */
