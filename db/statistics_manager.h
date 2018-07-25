#pragma once

#include <cassert>
#include <string>
#include <iostream>
#include <unordered_map>

namespace leveldb {

  class StatisticsManager {
  public:
    StatisticsManager() {}

    ~StatisticsManager() {}

    static StatisticsManager& GetInstance() {
      static StatisticsManager statistics_manager;
      return statistics_manager;
    }
  };
}