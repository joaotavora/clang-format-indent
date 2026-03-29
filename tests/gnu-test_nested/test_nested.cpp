// Tests: deeply nested control flow + mixed constructs
#include <vector>

namespace app {

class Processor {
 public:
  struct Config {
    int max_retries;
    bool verbose;
  };

  explicit Processor(Config cfg) : cfg_(cfg) {}

  int process(const std::vector<int>& data) {
    int result = 0;
    for (int i = 0; i < static_cast<int>(data.size()); ++i) {
      int val = data[i];
      if (val < 0) {
        continue;
      }
      for (int j = 0; j < cfg_.max_retries; ++j) {
        if (val % 2 == 0) {
          result += val;
        } else {
          result -= val;
        }
      }
    }
    return result;
  }

 private:
  Config cfg_;
};

}  // namespace app
