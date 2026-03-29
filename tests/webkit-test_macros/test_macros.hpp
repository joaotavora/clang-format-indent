#pragma once

#include <source_location>

namespace xpto::logger {
void log_impl(int level, const std::source_location& loc, const char* msg);
}

// BLOT_LOG_MAX_LEVEL controls compile-time logging ceiling (0=fatal..5=trace).
// If not defined, all log macros are no-ops.
#ifndef BLOT_LOG_MAX_LEVEL
#define BLOT_LOG_MAX_LEVEL 5
#endif

#if BLOT_LOG_MAX_LEVEL >= 5
#define LOG_TRACE(...)                                             \
  xpto::logger::log(                                               \
      xpto::logger::level::trace, std::source_location::current(), \
      __VA_ARGS__)
#else
#define LOG_TRACE(...) ((void)0)
#endif

#if BLOT_LOG_MAX_LEVEL >= 4
#define LOG_DEBUG(...)                                             \
  xpto::logger::log(                                               \
      xpto::logger::level::debug, std::source_location::current(), \
      __VA_ARGS__)
#else
#define LOG_DEBUG(...) ((void)0)
#endif

#if BLOT_LOG_MAX_LEVEL >= 3
#define LOG_INFO(...) \
  xpto::logger::log(  \
      xpto::logger::level::info, std::source_location::current(), __VA_ARGS__)
#else
#define LOG_INFO(...) ((void)0)
#endif

#if BLOT_LOG_MAX_LEVEL >= 2
#define LOG_WARN(...)                                                \
  xpto::logger::log(                                                 \
      xpto::logger::level::warning, std::source_location::current(), \
      __VA_ARGS__)
#else
#define LOG_WARN(...) ((void)0)
#endif

#if BLOT_LOG_MAX_LEVEL >= 1
#define LOG_ERROR(...)                                             \
  xpto::logger::log(                                               \
      xpto::logger::level::error, std::source_location::current(), \
      __VA_ARGS__)
#else
#define LOG_ERROR(...) ((void)0)
#endif

#if BLOT_LOG_MAX_LEVEL >= 0
#define LOG_FATAL(...)                                             \
  xpto::logger::log(                                               \
      xpto::logger::level::fatal, std::source_location::current(), \
      __VA_ARGS__)
#else
#define LOG_FATAL(...) ((void)0)
#endif
