int main() {
  app.add_option("--compile_commands,--ccj", path, "Path to compile_commands.json file")->type_name("CCJ-PATH");
  app.add_flag("--stdio", stdio_mode, "Start JSONRPC server on stdin/stdout (Content-Length framing)")->capture_default_str();
}
