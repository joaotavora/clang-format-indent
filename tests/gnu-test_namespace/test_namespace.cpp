// Tests: namespace body indentation (Google: NamespaceIndentation=None)
#include <string>

namespace outer {

int global_var = 42;

void free_function(int x) {
  if (x > 0) {
    x--;
  }
}

namespace inner {

class Nested {
 public:
  int value;
  void method() { value = 1; }
};

}  // namespace inner

}  // namespace outer
