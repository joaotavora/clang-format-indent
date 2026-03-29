# clang-format-indent

If you're:

* using the built-in Emacs `c-ts-mode` or `c++-ts-mode` for C/C++
* using `.clang-format` files in your project
* tired of `TAB` not match the the `clang-format` indentation

You can use this style to solve your problem

```
(setq c-ts-mode-indent-style 'clang-format-indent-style)
```

There's a decent change that marking a region and pressing `TAB` and
then asking `clang-format` to format that region keeps the code
untouched.  However, keep in mind Emacs's `indent-for-tab-command`
just cares about leading whitespace and does nothing for other parts
of formatting like adding or removing newlines.

This works by invoking `clang-format --dump-config` every time you
visit file and translating the [`clang-format` directives][1] into
[`c-ts-mode` indentation rules][2].

[1]: https://clang.llvm.org/docs/ClangFormatStyleOptions.html
[2]: https://www.gnu.org/software/emacs/manual/html_node/elisp/Parser_002dbased-Indentation.html

