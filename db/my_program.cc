#include <iostream>
#include <cassert>
#include <chrono>
#include <thread>
#include "leveldb/db.h"
#include "db_impl.h"
// #include "db/art.h"


int NumTableFilesAtLevel(leveldb::DB* db, int level) {
  std::string property;
      db->GetProperty("leveldb.num-files-at-level" + std::to_string(level),
                       &property);
  return atoi(property.c_str());
}


void test() {
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

// void test_art() {
//   art_tree t0;
//   art_tree_init(&t0);

//   uint64_t key0 = 100;
//   art_insert(&t0, (unsigned char *)(&key0), sizeof(uint64_t), 1000);

//   std::vector<uint64_t> found_values;
//   art_search(&t0, (unsigned char *)(&key0), sizeof(uint64_t), found_values);
//   std::cout << "found value count = " << found_values.size() << ": " << found_values[0] << std::endl;

//   art_tree t1;
//   art_tree_init(&t1);

//   uint64_t key1 = 99;
//   art_insert(&t1, (unsigned char *)(&key1), sizeof(uint64_t), 1001);

//   art_merge(&t0, &t1);

//   size_t size = art_size(&t0);
//   std::cout << "size = " << size << std::endl;


//   art_tree_destroy(&t0);
// }

int main(int argc, char *argv[]) {
  test();
}

