// Tests: long/complex lambdas that span many lines
#include <algorithm>
#include <functional>
#include <map>
#include <string>
#include <vector>

// ── Multi-line lambda body
// ────────────────────────────────────────────────────

void process_with_long_lambda() {
  std::vector<int> data = {5, 3, 8, 1, 9, 2, 7, 4, 6};

  auto is_interesting = [](int x) {
    if (x < 2) {
      return false;
    }
    for (int i = 2; i * i <= x; ++i) {
      if (x % i == 0) {
        return false;
      }
    }
    return true;
  };

  std::vector<int> result;
  std::copy_if(
      data.begin(), data.end(), std::back_inserter(result), is_interesting);
}

// ── Lambda with capture + multi-line body ────────────────────────────────────

void stateful_lambda(std::vector<std::string>& output) {
  int counter = 0;
  std::string prefix = "item";

  auto formatter = [&counter, &prefix, &output](const std::string& raw) {
    std::string formatted = prefix + "_" + std::to_string(counter) + ": " + raw;
    if (formatted.size() > 80) {
      formatted = formatted.substr(0, 77) + "...";
    }
    output.push_back(std::move(formatted));
    ++counter;
  };

  formatter("alpha");
  formatter("beta");
  formatter(
      "a very long string that might exceed the column limit if we are "
      "unlucky");
}

// ── Lambda passed as argument (multi-line) ───────────────────────────────────

void call_with_lambda() {
  std::vector<int> numbers = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};

  std::sort(numbers.begin(), numbers.end(), [](int a, int b) {
    int dist_a = (a > 5) ? (a - 5) : (5 - a);
    int dist_b = (b > 5) ? (b - 5) : (5 - b);
    if (dist_a != dist_b) {
      return dist_a < dist_b;
    }
    return a < b;
  });
}

// ── Lambda stored in std::function, multi-line ───────────────────────────────

std::function<std::vector<std::string>(const std::vector<int>&)> make_converter(
    const std::string& prefix, int offset) {
  return [prefix, offset](const std::vector<int>& values) {
    std::vector<std::string> result;
    result.reserve(values.size());
    for (int v : values) {
      result.push_back(prefix + std::to_string(v + offset));
    }
    return result;
  };
}

// ── Nested lambdas, multi-line ───────────────────────────────────────────────

void nested_long_lambdas() {
  auto outer = [](int n) {
    auto inner = [n](int m) {
      int result = 0;
      for (int i = 0; i < n; ++i) {
        for (int j = 0; j < m; ++j) {
          result += i * j;
        }
      }
      return result;
    };
    return inner;
  };

  auto fn = outer(4);
  int r = fn(3);
}

// ── Lambda capturing this (member context) ───────────────────────────────────

class Transformer {
 public:
  Transformer(std::string tag, int scale)
      : tag_(std::move(tag)), scale_(scale) {}

  std::function<std::string(int)> make_fn() const {
    return [this](int x) {
      int scaled = x * scale_;
      if (scaled < 0) {
        return tag_ + ":neg:" + std::to_string(scaled);
      } else if (scaled == 0) {
        return tag_ + ":zero";
      } else {
        return tag_ + ":pos:" + std::to_string(scaled);
      }
    };
  }

 private:
  std::string tag_;
  int scale_;
};

// ── Immediately-invoked long lambda ──────────────────────────────────────────

const std::map<std::string, int> kTable = [] {
  std::map<std::string, int> m;
  m["alpha"] = 1;
  m["beta"] = 2;
  m["gamma"] = 3;
  m["delta"] = 4;
  m["epsilon"] = 5;
  return m;
}();
