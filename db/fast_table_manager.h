#pragma once

#include <cassert>
#include <string>
#include <iostream>
#include <unordered_map>

#include "db/dbformat.h"
#include "leveldb/slice.h"

namespace leveldb {

  class FastTable {

  public:
    FastTable() {}

    ~FastTable() {}

    void Add(const std::string &key, const Slice &value) {
      table_.insert({key, value});
    }

    bool Get(const std::string &key, Slice &value) {
      auto entry = table_.find(key);
      if (entry == table_.end()) {
        return false;
      } else {
        value = entry->second;
        return true;
      }
    }

  private:
    std::unordered_map<std::string, Slice> table_;

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

}
