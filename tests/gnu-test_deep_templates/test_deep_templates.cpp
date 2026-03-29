// Tests: deeply nested template instantiations in argument lists
#include <functional>
#include <map>
#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

// ── Free functions with nested-template parameters ───────────────────────────

// Parameters are themselves complex template instantiations.
void process_nested(
    std::map<std::string, std::vector<std::pair<int, double>>>& data,
    const std::unordered_map<std::string, std::shared_ptr<std::vector<int>>>&
        cache,
    bool overwrite);

// Return type is a nested template; params also nest.
std::map<std::string, std::vector<std::pair<std::string, int>>> build_index(
    const std::vector<std::pair<std::string, std::vector<int>>>& raw_entries,
    std::size_t max_depth, bool case_sensitive);

// ── Template functions with template-template parameters ─────────────────────

// Template-template parameter plus nested value params.
template <
    template <typename, typename> class MapType, typename Key, typename Value>
MapType<Key, std::vector<Value>> group_by(
    const std::vector<std::pair<Key, Value>>& pairs,
    std::function<Key(const Value&)> key_fn);

// Multiple levels: each param is a specialisation of a different template.
template <
    typename InputKey, typename InputValue, typename OutputKey,
    typename OutputValue, typename Transformer>
std::map<OutputKey, std::vector<OutputValue>> transform_map(
    const std::map<InputKey, std::vector<InputValue>>& input,
    Transformer transform_fn, std::function<bool(const OutputKey&)> filter_fn);

// ── Class with deeply-nested member signatures ───────────────────────────────

template <
    typename Key, typename Value, typename Hash = std::hash<Key>,
    typename Equal = std::equal_to<Key>>
class NestedCache {
 public:
  using map_type = std::unordered_map<
      Key, std::vector<std::pair<Value, std::shared_ptr<Value>>>, Hash, Equal>;

  // Method: nested template params and return type.
  std::vector<std::pair<Key, std::shared_ptr<Value>>> lookup_all(
      const std::vector<Key>& keys, std::function<bool(const Value&)> predicate,
      std::size_t max_results) const;

  // Method: template-template param in signature.
  template <template <typename...> class Container>
  Container<Key> keys_matching(
      std::function<bool(const Key&, const Value&)> predicate) const;

 private:
  map_type store_;
};

// ── Definitions ──────────────────────────────────────────────────────────────

template <typename Key, typename Value, typename Hash, typename Equal>
std::vector<std::pair<Key, std::shared_ptr<Value>>>
NestedCache<Key, Value, Hash, Equal>::lookup_all(
    const std::vector<Key>& keys, std::function<bool(const Value&)> predicate,
    std::size_t max_results) const {
  std::vector<std::pair<Key, std::shared_ptr<Value>>> result;
  for (const auto& k : keys) {
    auto it = store_.find(k);
    if (it != store_.end()) {
      for (const auto& [val, ptr] : it->second) {
        if (predicate(val)) {
          result.emplace_back(k, ptr);
          if (result.size() >= max_results) {
            return result;
          }
        }
      }
    }
  }
  return result;
}
