// Tests: templates and nested types
#include <vector>

template <typename T>
class Stack {
 public:
  void push(const T& value) { data_.push_back(value); }
  void push(T&& value) { data_.push_back(std::move(value)); }
  T& top() { return data_.back(); }
  bool empty() const { return data_.empty(); }

 private:
  std::vector<T> data_;
};

template <typename Key, typename Value>
class Map {
 public:
  struct Entry {
    Key key;
    Value value;
  };
  void insert(const Key& k, const Value& v) { entries_.push_back({k, v}); }

 private:
  std::vector<Entry> entries_;
};

template <typename T>
T clamp(T value, T lo, T hi) {
  if (value < lo) {
    return lo;
  }
  if (value > hi) {
    return hi;
  }
  return value;
}
