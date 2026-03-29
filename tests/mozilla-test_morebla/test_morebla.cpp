struct find_action {
  find_action(
      const fs::path& needle, const fs::path& working_dir, bool& match,
      dead_set_t& dead_files)
      : needle_{needle},
        working_dir_{working_dir},
        match_{match},
        dead_files_{dead_files} {}
};
