int main() {
  std::string version;
  if (RE2::PartialMatch(output, gcc_re, &version) ||
      RE2::PartialMatch(output, clang_re, &version)) {
    return version;
  }
}
