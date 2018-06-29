#include <iostream>
#include <cassert>
#include "leveldb/db.h"
#include "db_impl.h"


  int NumTableFilesAtLevel(leveldb::DB* db, int level) {
    std::string property;
        db->GetProperty("leveldb.num-files-at-level" + std::to_string(level),
                         &property);
    return atoi(property.c_str());
  }

/*
int main(int argc, char** argv) {
  assert(argc == 2);
  int iter = atoi(argv[1]);
  leveldb::DB* db;
  leveldb::Options options;
  options.create_if_missing = true;
  leveldb::Status status = leveldb::DB::Open(options, "/tmp/testdb", &db);
  assert(status.ok());
  
  for (size_t i = 0; i < iter; ++i) {
  std::string key1 = std::to_string(i);
  // std::string key2 = "b";

  std::string value1(4096, '0');
  // std::string value2;
  leveldb::Status s = db->Put(leveldb::WriteOptions(), key1, value1);
  // s = db->Get(leveldb::ReadOptions(), key1, &value2);
}
  // std::cout << "value = " << value2 << std::endl;
  // if (s.ok()) s = db->Put(leveldb::WriteOptions(), key2, value);
  // if (s.ok()) s = db->Delete(leveldb::WriteOptions(), key1);

  delete db;
  db = nullptr;
}
*/

int main(int argc, char** argv) {
  leveldb::DB* db;
  leveldb::Options options;
  options.create_if_missing = true;
  leveldb::Status status = leveldb::DB::Open(options, "/tmp/testdb", &db);
  assert(status.ok());

  std::string small = "1";
  std::string large = "50";

  leveldb::Status s;
  s = db->Put(leveldb::WriteOptions(), small, "begin");
  s = db->Put(leveldb::WriteOptions(), large, "end");
  reinterpret_cast<leveldb::DBImpl*>(db)->TEST_CompactMemTable();

  for (size_t i = 0; i < leveldb::config::kNumLevels; ++i) {
    std::cout << "NumTableFilesAtLevel " << i << " = " << NumTableFilesAtLevel(db, i) << std::endl;
  }


  small = "6";
  large = "90";

  s = db->Put(leveldb::WriteOptions(), small, "begin");
  s = db->Put(leveldb::WriteOptions(), large, "end");
  reinterpret_cast<leveldb::DBImpl*>(db)->TEST_CompactMemTable();

  for (size_t i = 0; i < leveldb::config::kNumLevels; ++i) {
    std::cout << "NumTableFilesAtLevel " << i << " = " << NumTableFilesAtLevel(db, i) << std::endl;
  }

  reinterpret_cast<leveldb::DBImpl*>(db)->TEST_CompactRange(2, nullptr, nullptr);


  for (size_t i = 0; i < leveldb::config::kNumLevels; ++i) {
    std::cout << "NumTableFilesAtLevel " << i << " = " << NumTableFilesAtLevel(db, i) << std::endl;
  }

}