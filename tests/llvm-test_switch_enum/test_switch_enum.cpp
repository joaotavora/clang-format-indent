#include <cstdint>
#include <string_view>

namespace xpto::logger {

enum class level : uint8_t { fatal, error, warning, info, debug, trace };

inline std::string_view level_to_string(level level) {
  switch (level) {
    case level::trace:
      return "TRACE";
    case level::debug:
      return "DEBUG";
    case level::info:
      return "INFO";
    case level::warning:
      return "WARNING";
    case level::error:
      return "ERROR";
    case level::fatal:
      return "FATAL";
    default:
      return "UNKNOWN";
  }
}

}  // namespace xpto::logger
