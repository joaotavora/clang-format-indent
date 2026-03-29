// Tests: functions with many long-winded arguments (normal and template)
#include <functional>
#include <memory>
#include <string>
#include <vector>

// ── Free functions
// ────────────────────────────────────────────────────────────

// Short enough to fit on one line — no wrapping expected.
void short_func(int x, int y) {}

// Parameters that force a wrap (AlwaysBreak: each param on its own line,
// indented one ContinuationIndentWidth=4 from the function name column).
void long_function_with_many_parameters(
    int first_parameter, int second_parameter,
    const std::string& third_parameter, std::vector<int> fourth_parameter,
    bool fifth_parameter);

// Return type on its own line (trailing return type).
auto compute_result(
    const std::vector<std::string>& input_strings, std::size_t max_results,
    bool case_sensitive) -> std::vector<std::string>;

// Nested call as argument.
void outer_call(
    int simple_arg, std::string another_arg,
    std::shared_ptr<std::vector<int>> complex_arg);

// ── Member functions
// ──────────────────────────────────────────────────────────

class DataProcessor {
 public:
  // Constructor with many params.
  DataProcessor(
      std::string name, int capacity, bool enable_logging,
      std::shared_ptr<std::vector<std::string>> initial_data);

  // Method with many params.
  std::vector<int> process(
      const std::vector<int>& input, int batch_size, bool parallel,
      std::function<int(int)> transform);

  // Const method.
  bool validate(
      const std::string& key, const std::string& value, bool strict_mode) const;

 private:
  std::string name_;
  int capacity_;
};

// ── Template functions
// ────────────────────────────────────────────────────────

// Single template parameter, long arguments.
template <typename T>
T reduce(
    const std::vector<T>& values, T initial,
    std::function<T(T, T)> accumulator);

// Multiple template parameters.
template <typename Key, typename Value, typename Comparator>
std::vector<std::pair<Key, Value>> sorted_pairs(
    const std::vector<Key>& keys, const std::vector<Value>& values,
    Comparator comparator);

// Template member function.
template <typename InputIterator, typename OutputIterator, typename Predicate>
OutputIterator copy_if_transformed(
    InputIterator first, InputIterator last, OutputIterator out,
    Predicate pred);

// ── Template classes with long-argument methods
// ───────────────────────────────

template <typename T, typename Allocator = std::allocator<T>>
class Pipeline {
 public:
  // Method whose signature spans several lines.
  template <typename Transformer>
  Pipeline& add_stage(
      std::string stage_name, Transformer transform_fn, bool enabled = true);

  std::vector<T, Allocator> run(
      std::vector<T, Allocator> input, std::size_t max_concurrency,
      bool abort_on_error);

 private:
  std::vector<std::string> stage_names_;
};

// ── Function definitions (bodies) ────────────────────────────────────────────

void long_function_with_many_parameters(
    int first_parameter, int second_parameter,
    const std::string& third_parameter, std::vector<int> fourth_parameter,
    bool fifth_parameter) {
  if (first_parameter > second_parameter) {
    fourth_parameter.push_back(first_parameter);
  }
}

template <typename Key, typename Value, typename Comparator>
std::vector<std::pair<Key, Value>> sorted_pairs(
    const std::vector<Key>& keys, const std::vector<Value>& values,
    Comparator comparator) {
  std::vector<std::pair<Key, Value>> result;
  for (std::size_t i = 0; i < keys.size(); ++i) {
    result.push_back({keys[i], values[i]});
  }
  return result;
}
