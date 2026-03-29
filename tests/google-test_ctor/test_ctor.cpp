// Tests: constructor initializer lists
#include <string>
#include <vector>

class Widget {
 public:
  Widget(int x, int y, std::string label, bool visible)
      : x_(x), y_(y), label_(std::move(label)), visible_(visible) {}

  Widget() : Widget(0, 0, "", true) {}

  ~Widget() = default;

 private:
  int x_;
  int y_;
  std::string label_;
  bool visible_;
};

class DerivedWidget : public Widget {
 public:
  DerivedWidget(int x, int y) : Widget(x, y, "derived", true), extra_(0) {}

 private:
  int extra_;
};
