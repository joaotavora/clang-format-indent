// Tests: class with access specifiers (Google: AccessModifierOffset=-1)
#include <string>

class Base {
 public:
  Base() = default;
  virtual ~Base() = default;
  int get_value() const { return value_; }
  void set_value(int v) { value_ = v; }
  static int static_method() { return 0; }

 protected:
  virtual void on_change() {}
  int helper(int x) { return x * 2; }

 private:
  int value_ = 0;
  std::string name_;
};

struct SimpleStruct {
  int x;
  int y;
  float z;
};
