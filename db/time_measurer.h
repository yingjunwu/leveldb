#pragma once

#include <iostream>
#include <chrono>
#include <cassert>

using std::chrono::high_resolution_clock;
using std::chrono::milliseconds;
using std::chrono::microseconds;
using std::chrono::nanoseconds;

class TimeMeasurer {
public:
  TimeMeasurer() {}
  ~TimeMeasurer() {}

  void tic() {
    start_time_ = high_resolution_clock::now();
  }

  void toc() {
    end_time_ = high_resolution_clock::now();
  }

  long long time_ms() const {
    return std::chrono::duration_cast<milliseconds>(end_time_ - start_time_).count();
  }

  long long time_us() const {
    return std::chrono::duration_cast<microseconds>(end_time_ - start_time_).count();
  }

  long long time_ns() const {
    return std::chrono::duration_cast<nanoseconds>(end_time_ - start_time_).count();
  }

  void print_ms() const {
    std::cout << std::chrono::duration_cast<milliseconds>(end_time_ - start_time_).count() << " ms" << std::endl;
  }

  void print_us() const {
    std::cout << std::chrono::duration_cast<microseconds>(end_time_ - start_time_).count() << " us" << std::endl;
  }

  void print_ns() const {
    std::cout << std::chrono::duration_cast<nanoseconds>(end_time_ - start_time_).count() << " ns" << std::endl;
  }


private:
  TimeMeasurer(const TimeMeasurer&);
  TimeMeasurer& operator=(const TimeMeasurer&);

private:
  high_resolution_clock::time_point start_time_;
  high_resolution_clock::time_point end_time_;
};


template<size_t N>
class MultiTimeMeasurer {
public:
  MultiTimeMeasurer() : time_count_(0) {}
  ~MultiTimeMeasurer() {}

  void reset() { time_count_ = 0; }

  void tic() {
    assert(time_count_ == 0);
    start_time_ = high_resolution_clock::now();
  }

  void toc() {
    assert(time_count_ < N);
    end_times_[time_count_] = high_resolution_clock::now();
    time_count_++;
  }

  long long time_ms(const size_t time_id) const {
    assert(time_id < time_count_);
    return std::chrono::duration_cast<milliseconds>(end_times_[time_id] - start_time_).count();
  }

  long long time_us(const size_t time_id) const {
    assert(time_id < time_count_);
    return std::chrono::duration_cast<microseconds>(end_times_[time_id] - start_time_).count();
  }

  long long time_ns(const size_t time_id) const {
    assert(time_id < time_count_);
    return std::chrono::duration_cast<nanoseconds>(end_times_[time_id] - start_time_).count();
  }

  void print_ms(const size_t time_id) const {
    assert(time_id < time_count_);
    std::cout << std::chrono::duration_cast<milliseconds>(end_times_[time_id] - start_time_).count() << " ms" << std::endl;
  }

  void print_us(const size_t time_id) const {
    assert(time_id < time_count_);
    std::cout << std::chrono::duration_cast<microseconds>(end_times_[time_id] - start_time_).count() << " us" << std::endl;
  }

  void print_ns(const size_t time_id) const {
    assert(time_id < time_count_);
    std::cout << std::chrono::duration_cast<nanoseconds>(end_times_[time_id] - start_time_).count() << " ns" << std::endl;
  }


private:
  MultiTimeMeasurer(const MultiTimeMeasurer&);
  MultiTimeMeasurer& operator=(const MultiTimeMeasurer&);

private:
  high_resolution_clock::time_point start_time_;
  high_resolution_clock::time_point end_times_[N];
  size_t time_count_;
};
