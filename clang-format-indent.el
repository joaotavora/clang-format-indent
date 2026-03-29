;;; clang-format-indent.el --- c++-ts-mode indent style driven by .clang-format -*- lexical-binding: t; -*-

;; Author: João Távora <joaotavora@gmail.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1"))
;; Keywords: c languages tree-sitter
;; URL: https://github.com/joaotavora/clang-format-indent

(require 'c-ts-mode)

;;; --------------------------------------------------------------------
;;; Config reader
;;; --------------------------------------------------------------------

(defun cfi--parse-config ()
  "Run `clang-format --dump-config' in the current buffer's directory.
Return an alist of (KEY . VALUE) strings for top-level scalar fields."
  (let ((dir (or (and buffer-file-name
                      (file-name-directory buffer-file-name))
                 default-directory))
        result)
    (with-temp-buffer
      (let ((default-directory dir))
        (call-process "clang-format" nil t nil "--dump-config"))
      (goto-char (point-min))
      ;; Only match non-indented lines (top-level YAML scalars).
      ;; Indented lines belong to nested blocks like BraceWrapping and are ignored.
      (while (re-search-forward
              "^\\([A-Za-z][A-Za-z0-9_]*\\):[[:space:]]*\\([^#\n]*\\)" nil t)
        (let ((val (string-trim (match-string 2))))
          (unless (string-empty-p val)
            (push (cons (match-string 1) val) result)))))
    (nreverse result)))

(defun cfi--get (cfg key default)
  "Return string value for KEY in CFG alist, or DEFAULT."
  (alist-get key cfg default nil #'equal))

(defun cfi--int (cfg key default)
  "Return integer value for KEY in CFG alist, or DEFAULT."
  (let ((v (cfi--get cfg key nil)))
    (if v (string-to-number v) default)))

(defun cfi--bool (cfg key default)
  "Return boolean value for KEY in CFG alist, or DEFAULT."
  (let ((v (cfi--get cfg key nil)))
    (if v (equal v "true") default)))

;;;###autoload
(defun clang-format-indent-style ()
  "Indent C++ from the .clang-format visible to the current buffer.

Calls `clang-format --dump-config' to read the active style, then
translates settings that directly affect indentation into
`treesit-simple-indent-rules'."
  (let* ((cfg           (cfi--parse-config))
         (indent-width  (cfi--int  cfg "IndentWidth"                     2))
         (cont-indent   (cfi--int  cfg "ContinuationIndentWidth"         4))
         (ctor-indent   (cfi--int  cfg "ConstructorInitializerIndentWidth" 4))
         (access-offset (cfi--int  cfg "AccessModifierOffset"            -2))
         (indent-cases  (cfi--bool cfg "IndentCaseLabels"                nil))
         (ns-indent     (cfi--get  cfg "NamespaceIndentation"            "None"))
         ;; clang-format 22+ splits AlignAfterOpenBracket into
         ;; per-context fields.  BreakAfterOpenBracketFunction: true ≡
         ;; old AlwaysBreak for calls/decls.  Fall back to the legacy
         ;; AlignAfterOpenBracket for older versions.
         (break-fn      (cfi--get  cfg "BreakAfterOpenBracketFunction"   nil))
         (align-open    (cfi--get  cfg "AlignAfterOpenBracket"           "Align"))
         (always-break  (if break-fn
                            (equal break-fn "true")
                          (member align-open '("AlwaysBreak" "BlockIndent"))))
         (brace-style   (cfi--get  cfg "BreakBeforeBraces"               "Attach"))
         (ctor-break    (cfi--get  cfg "BreakConstructorInitializers"    "BeforeColon"))
         ;; BeforeComma: ', y_' aligns with ':' → parent 0.
         ;; BeforeColon / AfterColon: values align 2 past ':' (after ': ') → parent 2.
         (ctor-cont-col (if (equal ctor-break "BeforeComma") 0 2))
         ;; IndentBraces is true only in GNU brace style.  When false, a '{'
         ;; on its own line sits at the same column as its controlling statement
         ;; (not indented one level further as K&R baseline would give).
         (indent-braces (equal brace-style "GNU"))
         (access-col    (+ indent-width access-offset))
         (k&r-rules     (cdr (assq 'cpp (c-ts-mode--simple-indent-rules 'cpp 'k&r)))))

    ;; Keep c-ts-indent-offset in sync; K&R rules reference it by symbol.
    (setq c-ts-indent-offset indent-width)

    `((cpp
       ;; --- Namespace body ---
       ;; NamespaceIndentation: None / Inner → not indented (parent-bol 0)
       ;; NamespaceIndentation: All          → indented one level
       ;;
       ;; Two rules needed:
       ;; (a) n-p-gp: matches content nodes *inside* declaration_list.
       ;; (b) node-is "declaration_list": matches the '{' line itself
       ;;     (GNU/Allman brace style) where treesit--indent-largest-node-at
       ;;     returns the declaration_list node, not '{'.
       ,@(cond
           ((equal ns-indent "All")
            `(((and (node-is "declaration_list")
                    (parent-is "namespace_definition"))
               standalone-parent ,indent-width)
              ((n-p-gp nil "declaration_list" "namespace_definition")
               parent-bol ,indent-width)))
           ((equal ns-indent "Inner")
            ;; Only nested (inner) namespaces get indented; the outermost
            ;; namespace body stays at column 0.  Detect nesting by checking
            ;; whether the namespace_definition's parent is itself inside a
            ;; declaration_list (i.e. another namespace body).
            `(((and (node-is "declaration_list")
                    (parent-is "namespace_definition")
                    (lambda (node parent _bol)
                      (equal (treesit-node-type
                               (treesit-node-parent
                                (treesit-node-parent parent)))
                             "declaration_list")))
               standalone-parent ,indent-width)
              ((and (not (node-is "}"))
                    (n-p-gp nil "declaration_list" "namespace_definition")
                    (lambda (node parent _bol)
                      (equal (treesit-node-type
                               (treesit-node-parent
                                (treesit-node-parent parent)))
                             "declaration_list")))
               parent-bol ,indent-width)
              ;; Outer namespace: no indent.
              ((and (node-is "declaration_list")
                    (parent-is "namespace_definition"))
               standalone-parent 0)
              ((n-p-gp nil "declaration_list" "namespace_definition")
               parent-bol 0)))
           (t
            `(((and (node-is "declaration_list")
                    (parent-is "namespace_definition"))
               standalone-parent 0)
              ((n-p-gp nil "declaration_list" "namespace_definition")
               parent-bol 0))))

       ;; --- case/default labels ---
       ;; K&R emits (node-is "case") → standalone-parent 0.
       ;; When IndentCaseLabels is true we need standalone-parent + indent-width
       ;; instead, so we prepend a more-specific override.
       ,@(when indent-cases
           `(((and (node-is "case")
                   (parent-is "compound_statement"))
              standalone-parent ,indent-width)))

       ;; --- access specifiers ---
       ;; K&R has parent-bol 0; override with the computed column
       ;; (same value for LLVM/GNU, shadowing K&R harmlessly).
       ((node-is "access_specifier") parent-bol ,access-col)

       ;; --- constructor initializer list ---
       ;; The ':' line (field_initializer_list at BOL when wrapped).
       ((node-is "field_initializer_list") standalone-parent ,ctor-indent)
       ;; Subsequent initializer items align relative to ':'.
       ;; BeforeComma style: ', y_' at ':' column → parent 0.
       ;; BeforeColon style: values after ': ' → parent 2 (skipping ': ').
       ((parent-is "field_initializer_list") parent ,ctor-cont-col)

       ;; --- class/struct body opening brace (Allman/GNU brace style) ---
       ;; treesit--indent-largest-node-at returns the *largest* node whose start
       ;; equals the line's first character.  When '{' is on its own line,
       ;; that largest node is field_declaration_list itself (it starts at '{').
       ;; Use standalone-parent (not parent) so that a class inside a template
       ;; declaration walks up past class_specifier (not at BOL) to
       ;; template_declaration (at BOL, col 0).
       ((node-is "field_declaration_list") standalone-parent 0)

       ;; --- class/struct body members ---
       ;; Without this, c-ts-common-baseline-indent-rule (condition-2b) aligns
       ;; to the first named child of field_declaration_list, which may be an
       ;; access_specifier at col access-col rather than the class body column.
       ((and (not (node-is "access_specifier"))
             (not (node-is "}"))
             (parent-is "field_declaration_list"))
        standalone-parent ,indent-width)

       ;; --- enum body opening brace (Allman/GNU brace style) ---
       ;; Same issue as field_declaration_list: when '{' is on its own line,
       ;; treesit--indent-largest-node-at returns enumerator_list itself.
       ((node-is "enumerator_list") standalone-parent 0)

       ;; --- enum members ---
       ;; K&R condition-2b aligns continuations to the first enumerator, which
       ;; is wrong when the opening '{' and first value are on the same line
       ;; (e.g. WebKit inline enums: "enum Foo { A,\n    B }").
       ;; standalone-parent walks up past enumerator_list (which starts at '{',
       ;; never at BOL when inline) to the enum_specifier at BOL, giving the
       ;; correct IndentWidth-from-enum-keyword indent.
       ((and (not (node-is "}"))
             (parent-is "enumerator_list"))
        standalone-parent ,indent-width)

       ;; --- catch clause ---
       ;; K&R has no catch_clause rule; condition 3 gives standalone-parent +
       ;; IndentWidth.  catch should align with try (standalone-parent 0).
       ((node-is "catch_clause") standalone-parent 0)

       ;; --- compound_statement brace on its own line (non-GNU brace styles) ---
       ;; For GNU (IndentBraces: true) K&R baseline gives standalone-parent +
       ;; indent-width which is correct.  For all other styles (Allman, Microsoft,
       ;; Mozilla, WebKit – IndentBraces: false) the '{' sits at the same column
       ;; as its controlling statement, so we need standalone-parent 0.
       ;; Harmless for Attach-brace styles (Google/LLVM) where '{' is never at BOL.
       ,@(unless indent-braces
           `(((node-is "compound_statement") standalone-parent 0)))

       ;; --- binary expression continuation ---
       ;; Right-hand operand of a wrapped binary expression (||, &&, +, …)
       ;; should align with the left operand.  binary_expression starts at its
       ;; left operand, so 'parent 0' gives that column directly.
       ;; standalone-parent walks past binary_expression (which is mid-line
       ;; inside e.g. an if-condition paren) and lands on the wrong anchor.
       ((parent-is "binary_expression") parent 0)

       ;; --- variable initializer / using-alias continuation ---
       ;; When the RHS of "T name = <value>" or "using T = <type>" wraps to
       ;; the next line, K&R baseline gives standalone-parent + IndentWidth.
       ;; We want standalone-parent + ContinuationIndentWidth instead.
       ((parent-is "init_declarator") standalone-parent ,cont-indent)
       ((parent-is "alias_declaration") standalone-parent ,cont-indent)

       ;; --- method chain: '->' or '.' at start of continuation line ---
       ;; Use 'parent' (not standalone-parent) so that when the chained object
       ;; starts mid-line (e.g. "name = (expr)\n    .method()") the anchor is
       ;; the object's column rather than the enclosing statement's column.
       ((and (or (node-is "->") (node-is "."))
             (parent-is "field_expression"))
        parent ,cont-indent)

       ;; --- trailing return type: auto f(...)\n    -> ReturnType ---
       ((node-is "trailing_return_type") standalone-parent ,cont-indent)

       ;; --- AlwaysBreak / BlockIndent specific rules ---
       ;; These are omitted for Align mode; K&R baseline aligns to first sibling.
       ,@(when always-break
           `(;; Args of a call that is itself the receiver of a '->chain()'.
             ;; Indent 2*ContinuationIndentWidth-1 to visually separate from
             ;; the following '->' line (mirrors clang-format's heuristic).
             ((lambda (node parent bol-pos)
                (and (not (string= (treesit-node-type node) ")"))
                     (string= (treesit-node-type parent) "argument_list")
                     (let* ((call (treesit-node-parent parent))
                            (call-parent (and call (treesit-node-parent call))))
                       (and call-parent
                            (string= (treesit-node-type call-parent)
                                     "field_expression")))))
              standalone-parent ,(- (* 2 cont-indent) 1))

             ;; Wrapped parameters and arguments.
             ((and (not (node-is ")"))
                   (or (parent-is "parameter_list")
                       (parent-is "argument_list")))
              standalone-parent ,cont-indent)

             ((n-p-gp nil "pointer_declarator" "parameter_declaration")
              standalone-parent ,cont-indent)))

       ;; --- Parameter name on its own line after a long type ---
       ;; (e.g. "const Foo&\n    name").  Applies in both modes.
       ;; Two patterns: (a) the identifier ("name") wraps → n-p-gp matches
       ;; because "name" is inside reference_declarator.
       ;; (b) the "&name" wraps → reference_declarator itself is at BOL,
       ;; so node-is matches.
       ((and (node-is "reference_declarator")
             (parent-is "parameter_declaration"))
        standalone-parent ,cont-indent)
       ((and (node-is "pointer_declarator")
             (parent-is "parameter_declaration"))
        standalone-parent ,cont-indent)
       ((n-p-gp nil "reference_declarator" "parameter_declaration")
        standalone-parent ,cont-indent)
       ((n-p-gp nil "pointer_declarator" "parameter_declaration")
        standalone-parent ,cont-indent)

       ;; --- function name on its own line after ref/ptr return type ---
       ;; e.g. "T &\ntop ()" in GNU style.  K&R has a (match "function_declarator"
       ;; nil "declarator") rule but the tree-sitter grammar does not place
       ;; function_declarator in a named field of reference/pointer_declarator,
       ;; so that rule never fires.  parent-bol 0 aligns to the return-type line.
       ((and (node-is "function_declarator")
             (parent-is "reference_declarator"))
        parent-bol 0)
       ((and (node-is "function_declarator")
             (parent-is "pointer_declarator"))
        parent-bol 0)

       ;; --- Align-mode specific rules ---
       ,@(unless always-break
           `(;; Chained call with ( at EOL: deeper indent to visually separate
             ;; from the following ->chain() line.
             ;; When the method and its receiver are on the same line (e.g.
             ;; "app.add_flag ("), use standalone-parent + 2*cont-1.
             ;; When the method is on its own line starting with '.' or '->'
             ;; (Mozilla/WebKit multi-line chain), use BOI-of-(-line + cont.
             ((lambda (node parent bol-pos)
                (and (not (string= (treesit-node-type node) ")"))
                     (string= (treesit-node-type parent) "argument_list")
                     (let* ((open (treesit-node-child parent 0))
                            (first-arg (treesit-node-child parent 0 t)))
                       (and open first-arg
                            (/= (line-number-at-pos (treesit-node-start first-arg))
                                (line-number-at-pos (treesit-node-end open)))))
                     (let* ((call (treesit-node-parent parent))
                            (call-parent (and call (treesit-node-parent call))))
                       (and call-parent
                            (string= (treesit-node-type call-parent)
                                     "field_expression")))))
              (lambda (node parent _bol)
                (save-excursion
                  (goto-char (treesit-node-start parent))
                  (back-to-indentation)
                  (let ((boi-col (current-column))
                        (bol (line-beginning-position)))
                    (if (memq (char-after) '(?. ?-))
                        (+ bol boi-col ,cont-indent)
                      (+ bol boi-col (- (* 2 ,cont-indent) 1))))))
              0)

             ;; ( at EOL (non-chained): standalone-parent + ContinuationIndentWidth.
             ((lambda (node parent bol-pos)
                (and (not (string= (treesit-node-type node) ")"))
                     (not (string= (treesit-node-type node) ">"))
                     (or (string= (treesit-node-type parent) "argument_list")
                         (string= (treesit-node-type parent) "parameter_list")
                         (string= (treesit-node-type parent) "template_argument_list"))
                     (let* ((open (treesit-node-child parent 0))
                            (first-arg (treesit-node-child parent 0 t)))
                       (and open first-arg
                            (/= (line-number-at-pos (treesit-node-start first-arg))
                                (line-number-at-pos (treesit-node-end open)))))))
              standalone-parent ,cont-indent)

             ;; ( or < and first-arg on same line (non-EOL), non-first sibling:
             ;; align to the column after the opening delimiter.
             ;; K&R's prev-standalone-sibling heuristic can return the wrong
             ;; column when the call starts with '.' or '->' on a new line
             ;; (method-chaining), so we override it here.
             ;; Also handles template_argument_list: K&R condition 2 only fires
             ;; for '(' and '[', not '<', so template args fall to condition 3
             ;; (standalone-parent + offset) which is also wrong.
             ((lambda (node parent bol-pos)
                (and (not (string= (treesit-node-type node) ")"))
                     (not (string= (treesit-node-type node) ">"))
                     (or (string= (treesit-node-type parent) "argument_list")
                         (string= (treesit-node-type parent) "parameter_list")
                         (string= (treesit-node-type parent) "template_argument_list"))
                     (let* ((open (treesit-node-child parent 0))
                            (first-arg (treesit-node-child parent 0 t)))
                       (and open first-arg
                            (= (line-number-at-pos (treesit-node-start first-arg))
                               (line-number-at-pos (treesit-node-end open)))))))
              parent 1)

             ;; Template parameter continuation: align to column after '<'
             ;; when the first param is on the same line as '<'.
             ((lambda (node parent bol-pos)
                (and (string= (treesit-node-type parent) "template_parameter_list")
                     (not (string= (treesit-node-type node) ">"))
                     (let* ((first-child (treesit-node-child parent 0 t)))
                       (and first-child
                            (= (line-number-at-pos (treesit-node-start first-child))
                               (line-number-at-pos (treesit-node-start parent)))))))
              parent 1)))

       ;; --- concatenated string literals ---
       ;; Use 'parent' anchor: the concatenated_string node starts at the first
       ;; string literal, so 'parent 0' aligns continuation strings to that column.
       ;; Works for both Align (first string at paren-aligned col) and AlwaysBreak
       ;; (first string at standalone-parent + cont-indent).
       ((parent-is "concatenated_string") parent 0)

       ;; --- multi-line function-like macro body ---
       ((and (node-is "preproc_arg")
             (parent-is "preproc_function_def"))
        standalone-parent ,indent-width)
       ((and no-node
             (parent-is "preproc_arg"))
        standalone-parent ,cont-indent)

       ;; --- remaining K&R rules ---
       ,@k&r-rules))))

(provide 'clang-format-indent)

;; Local Variables:
;; read-symbol-shorthands: (("cfi-" . "clang-format-indent-"))
;; End:
;;; clang-format-indent.el ends here
