#include <iostream>
#include <cassert>
#include <chrono>
#include <thread>
#include "leveldb/db.h"
#include "db_impl.h"


int NumTableFilesAtLevel(leveldb::DB* db, int level) {
  std::string property;
      db->GetProperty("leveldb.num-files-at-level" + std::to_string(level),
                       &property);
  return atoi(property.c_str());
}


int main(int argc, char** argv) {
  leveldb::DB* db;
  leveldb::Options options;
  options.create_if_missing = true;
  leveldb::Status status = leveldb::DB::Open(options, "/tmp/testdb", &db);
  assert(status.ok());

  leveldb::Status s;

  std::string small = "1";
  std::string large = "60";

  s = db->Put(leveldb::WriteOptions(), small, "begin");
  s = db->Put(leveldb::WriteOptions(), large, "end");
  reinterpret_cast<leveldb::DBImpl*>(db)->TEST_CompactMemTable();

  for (size_t i = 0; i < leveldb::config::kNumLevels; ++i) {
    std::cout << "NumTableFilesAtLevel " << i << " = " << NumTableFilesAtLevel(db, i) << std::endl;
  }


  small = "2";
  large = "80";

  s = db->Put(leveldb::WriteOptions(), small, "begin");
  s = db->Put(leveldb::WriteOptions(), large, "end");
  reinterpret_cast<leveldb::DBImpl*>(db)->TEST_CompactMemTable();

  for (size_t i = 0; i < leveldb::config::kNumLevels; ++i) {
    std::cout << "NumTableFilesAtLevel " << i << " = " << NumTableFilesAtLevel(db, i) << std::endl;
  }

  std::string start_str = "1";
  std::string end_str = "9";

  leveldb::Slice start_slice(start_str);
  leveldb::Slice end_slice(end_str);

  // reinterpret_cast<leveldb::DBImpl*>(db)->TEST_CompactRange(2, &start_slice, &end_slice);

  reinterpret_cast<leveldb::DBImpl*>(db)->TEST_CompactRange(1, nullptr, nullptr);

  for (size_t i = 0; i < leveldb::config::kNumLevels; ++i) {
    std::cout << "NumTableFilesAtLevel " << i << " = " << NumTableFilesAtLevel(db, i) << std::endl;
  }
  
  // std::this_thread::sleep_for (std::chrono::seconds(1));

  std::string key = "80";
  std::string value;
  s = db->Get(leveldb::ReadOptions(), key, &value);
  if (s.ok()) {
    std::cout << "ok! value = " << value << std::endl;
  } else {
    std::cout << "not ok..." << std::endl;
  }

}