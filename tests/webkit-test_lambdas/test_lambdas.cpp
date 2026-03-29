// Tests: lambdas (C++11/14/17/20)
#include <algorithm>
#include <functional>
#include <vector>

// Simple lambda assigned to auto
void basic_lambdas() {
  auto greet = []() { return 42; };

  auto add = [](int a, int b) { return a + b; };

  // Immediately invoked
  int x = [](int n) { return n * 2; }(21);
}

// Capture modes
void capture_lambdas(int base) {
  auto by_value = [base](int x) { return x + base; };

  auto by_ref = [&base](int x) { base += x; };

  auto capture_all_val = [=](int x) { return x + base; };

  auto capture_all_ref = [&](int x) {
    base += x;
    return base;
  };

  auto mixed = [base, &capture_all_ref](int x) { return x + base; };
}

// Explicit return type
void explicit_return() {
  auto divide = [](double a, double b) -> double {
    if (b == 0.0) {
      return 0.0;
    }
    return a / b;
  };

  auto classify = [](int x) -> const char* {
    if (x < 0) {
      return "negative";
    } else if (x == 0) {
      return "zero";
    } else {
      return "positive";
    }
  };
}

// Generic lambdas (C++14)
void generic_lambdas() {
  auto identity = [](auto x) { return x; };

  auto pair_sum = [](auto a, auto b) { return a + b; };
}

// Mutable lambda (C++11)
void mutable_lambda() {
  int counter = 0;
  auto inc = [counter]() mutable { return ++counter; };
}

// Lambda in STL algorithms
void stl_use() {
  std::vector<int> v = {3, 1, 4, 1, 5, 9, 2, 6};

  std::sort(v.begin(), v.end(), [](int a, int b) { return a < b; });

  std::for_each(v.begin(), v.end(), [](int x) {
    if (x % 2 == 0) {
      return;
    }
  });

  auto it = std::find_if(v.begin(), v.end(), [](int x) { return x > 4; });
}

// Nested lambdas
void nested_lambdas() {
  auto outer = [](int x) {
    auto inner = [x](int y) { return x + y; };
    return inner(10);
  };
}

// Lambda stored in std::function
void stored_lambda() {
  std::function<int(int, int)> op;
  op = [](int a, int b) { return a * b; };
}

// Immediately invoked complex lambda
int computed = [](int base) {
  int result = 0;
  for (int i = 0; i < base; ++i) {
    result += i * i;
  }
  return result;
}(10);

// C++20: lambda with template parameter list
void cpp20_lambdas() {
  auto typed = []<typename T>(T a, T b) { return a + b; };
}
