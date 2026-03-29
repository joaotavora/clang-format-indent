int main() {
  fs::path tu_file_blab_bla_bla =
      (working_dir / fs::path{"bla"}).lexically_normal();
  fs::path tu_file = (working_dir / fs::path{"blablablablablablablablablabla"})
                         .lexically_normal();
}
