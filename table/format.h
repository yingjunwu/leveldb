// Copyright (c) 2011 The LevelDB Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file. See the AUTHORS file for names of contributors.

#ifndef STORAGE_LEVELDB_TABLE_FORMAT_H_
#define STORAGE_LEVELDB_TABLE_FORMAT_H_

#include <string>
#include <stdint.h>
#include "leveldb/slice.h"
#include "leveldb/status.h"
#include "leveldb/table_builder.h"

namespace leveldb {

class Block;
class RandomAccessFile;
struct ReadOptions;

// BlockHandle is a pointer to the extent of a file that stores a data
// block or a meta block.
class BlockHandle {
 public:
  BlockHandle();

  // The offset of the block in the file.
  uint64_t offset() const { return offset_; }
  void set_offset(uint64_t offset) { offset_ = offset; }

  // The size of the stored block
  uint64_t size() const { return size_; }
  void set_size(uint64_t size) { size_ = size; }

  void EncodeTo(std::string* dst) const;
  Status DecodeFrom(Slice* input);

  // Maximum encoding length of a BlockHandle
  enum { kMaxEncodedLength = 10 + 10 };

 private:
  uint64_t offset_;
  uint64_t size_;
};

// KVBlockHandle is a pointer to the extent of a file that stores a kv pair
// in a data block.
class KVBlockHandle {
 public:
  KVBlockHandle();

  KVBlockHandle(const uint64_t offset, const uint64_t size, const uint64_t position);

  // The offset of the data block in the file.
  uint64_t offset() const { return offset_; }
  void set_offset(uint64_t offset) { offset_ = offset; }

  // The size of the stored block
  uint64_t size() const { return size_; }
  void set_size(uint64_t size) { size_ = size; }

  // The position of the targeted value in the block.
  uint64_t position() const { return position_; }
  void set_position(uint64_t position) { position_ = position; }

 private:
  uint64_t offset_;
  uint64_t size_;
  uint64_t position_;

};

// Footer encapsulates the fixed information stored at the tail
// end of every table file.
class Footer {
 public:
  Footer() { }

  // The block handle for the metaindex block of the table
  const BlockHandle& metaindex_handle() const { return metaindex_handle_; }
  void set_metaindex_handle(const BlockHandle& h) { metaindex_handle_ = h; }

  // The block handle for the index block of the table
  const BlockHandle& index_handle() const {
    return index_handle_;
  }
  void set_index_handle(const BlockHandle& h) {
    index_handle_ = h;
  }

  void EncodeTo(std::string* dst) const;
  Status DecodeFrom(Slice* input);

  // Encoded length of a Footer.  Note that the serialization of a
  // Footer will always occupy exactly this many bytes.  It consists
  // of two block handles and a magic number.
  enum {
    kEncodedLength = 2*BlockHandle::kMaxEncodedLength + 8
  };

 private:
  BlockHandle metaindex_handle_;
  BlockHandle index_handle_;
};

// kTableMagicNumber was picked by running
//    echo http://code.google.com/p/leveldb/ | sha1sum
// and taking the leading 64 bits.
static const uint64_t kTableMagicNumber = 0xdb4775248b80fb57ull;

// 1-byte type + 32-bit crc
static const size_t kBlockTrailerSize = 5;

struct BlockContents {
  Slice data;           // Actual contents of data
  bool cachable;        // True iff data can be cached
  bool heap_allocated;  // True iff caller should delete[] data.data()
};

// Read the block identified by "handle" from "file".  On failure
// return non-OK.  On success fill *result and return OK.
extern Status ReadBlock(RandomAccessFile* file,
                        const ReadOptions& options,
                        const BlockHandle& handle,
                        BlockContents* result);

// Implementation details follow.  Clients should ignore,

inline BlockHandle::BlockHandle()
    : offset_(~static_cast<uint64_t>(0)),
      size_(~static_cast<uint64_t>(0)) {
}

inline KVBlockHandle::KVBlockHandle()
    : offset_(~static_cast<uint64_t>(0)), 
      size_(~static_cast<uint64_t>(0)), 
      position_(~static_cast<uint64_t>(0)) {
}

inline KVBlockHandle::KVBlockHandle(const uint64_t offset, 
                                    const uint64_t size, 
                                    const uint64_t position)
    : offset_(offset), 
      size_(size),
      position_(position) {
}



  class FastTable {

    public:
      FastTable() {}

      ~FastTable() {}

      void Add(const char* data, const size_t size, const KVBlockHandle &handle) {
        table_.insert( { std::string(data, size), handle } );
      }

      bool Get(const char *data, const size_t size, KVBlockHandle &handle) {
        auto entry = table_.find(std::string(data, size));
        if (entry == table_.end()) {
          return false;
        } else {
          handle = entry->second;
          return true;
        }
      }

    private:
      std::unordered_map<std::string, KVBlockHandle> table_;

  };

  class FastTableManager {

  public:
    FastTableManager() {}

    ~FastTableManager() {}

    static FastTableManager& GetInstance() {
      static FastTableManager fast_table_manager;
      return fast_table_manager;
    }

    FastTable* NewFastTable(const uint64_t file_number) {
      assert(fast_tables_.find(file_number) == fast_tables_.end());
      FastTable* table = new FastTable();
      fast_tables_[file_number] = table;
      return table;
    }

    FastTable* GetFastTable(const uint64_t file_number) {
      assert(fast_tables_.find(file_number) != fast_tables_.end());
      return fast_tables_[file_number];
    }

    void DeleteFastTable(const uint64_t file_number) {
      assert(fast_tables_.find(file_number) != fast_tables_.end());
      FastTable* table = fast_tables_.at(file_number);
      delete table;
      table = nullptr;
      fast_tables_.erase(file_number); 
    }


  private:
     std::unordered_map<uint64_t, FastTable*> fast_tables_;

  };





}  // namespace leveldb

#endif  // STORAGE_LEVELDB_TABLE_FORMAT_H_
