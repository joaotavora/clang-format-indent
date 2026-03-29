#!/usr/bin/env bash
# run_tests.sh — compare Emacs indent-region against clang-format fixtures.
#
# Usage: run_tests.sh [FILTER]
#   FILTER  optional substring; only test dirs whose name contains it are run.
#
# Each subdirectory of tests/ is one test case and must contain:
#   - a .clang-format style file
#   - exactly one .cpp or .hpp source file (the fixture)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EMACS="${EMACS:-$HOME/Source/Emacs/emacs/src/emacs}"
STYLE_EL="$SCRIPT_DIR/clang-format-indent.el"
TESTS_DIR="$SCRIPT_DIR/tests"
FILTER="${1:-}"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

colorize() {
    case "$2" in
        green)  printf '\033[32m%s\033[0m\n' "$1" ;;
        red)    printf '\033[31m%s\033[0m\n' "$1" ;;
        yellow) printf '\033[33m%s\033[0m\n' "$1" ;;
        *)      printf '%s\n' "$1" ;;
    esac
}

run_one() {
    local test_dir="$1"
    local test_name
    test_name=$(basename "$test_dir")

    local fixture=""
    for f in "$test_dir"*.cpp "$test_dir"*.hpp; do
        [[ -f "$f" ]] && fixture="$f" && break
    done

    local style_file="$test_dir.clang-format"

    if [[ -z "$fixture" || ! -f "$style_file" ]]; then
        echo "SKIP" > "$WORKDIR/$test_name.status"
        return
    fi

    local base ext
    base=$(basename "$fixture")
    ext="${base##*.}"

    local test_workdir="$WORKDIR/$test_name"
    mkdir -p "$test_workdir"
    local formatted="$test_workdir/formatted.${ext}"
    local fumbled="$test_workdir/$base"
    local result="$test_workdir/result.${ext}"

    clang-format --style="file:$style_file" "$fixture" > "$formatted"
    sed 's/^[[:space:]]*//' "$formatted" > "$fumbled"
    cp "$style_file" "$test_workdir/.clang-format"

    "$EMACS" -Q --batch \
        -L "$SCRIPT_DIR" \
        -l "$STYLE_EL" \
        --visit "$fumbled" \
        --eval "(setq c-ts-mode-indent-style (quote clang-format-indent-style))" \
        --eval "(setq-default indent-tabs-mode nil)" \
        --eval "(c++-ts-mode)" \
        --eval "(indent-region (point-min) (point-max))" \
        --eval "(write-file \"$result\" nil)" \
        2>/dev/null

    if diff -u "$formatted" "$result" > "$test_workdir/test.diff" 2>&1; then
        echo "PASS" > "$WORKDIR/$test_name.status"
    elif [[ -f "$test_dir.known-failure" ]]; then
        echo "XFAIL" > "$WORKDIR/$test_name.status"
    else
        echo "FAIL" > "$WORKDIR/$test_name.status"
    fi
}

export -f run_one
export WORKDIR EMACS STYLE_EL

# Collect matching test dirs.
tests=()
for test_dir in "$TESTS_DIR"/*/; do
    [[ -d "$test_dir" ]] || continue
    test_name=$(basename "$test_dir")
    [[ -z "$FILTER" || "$test_name" == *"$FILTER"* ]] || continue
    tests+=("$test_dir")
done

if [[ ${#tests[@]} -eq 0 ]]; then
    echo "No tests match filter: $FILTER"
    exit 1
fi

# Start all tests in parallel, announcing each launch.
pids=()
for test_dir in "${tests[@]}"; do
    test_name=$(basename "$test_dir")
    echo "Start: $test_name"
    run_one "$test_dir" &
    pids+=($!)
done

echo ""

# Wait and print completion as each finishes (in launch order).
for i in "${!pids[@]}"; do
    wait "${pids[$i]}" || true
    test_name=$(basename "${tests[$i]}")
    status_file="$WORKDIR/$test_name.status"
    status=$([[ -f "$status_file" ]] && cat "$status_file" || echo "SKIP")
    case "$status" in
        PASS)  colorize "PASS:  $test_name" green ;;
        FAIL)  colorize "FAIL:  $test_name" red ;;
        XFAIL) colorize "XFAIL: $test_name" yellow ;;
        *)     colorize "SKIP:  $test_name" yellow ;;
    esac
done

echo ""

# Print diffs for all unexpected failures.
for test_dir in "${tests[@]}"; do
    test_name=$(basename "$test_dir")
    status_file="$WORKDIR/$test_name.status"
    [[ -f "$status_file" && "$(cat "$status_file")" == "FAIL" ]] || continue
    diff_file="$WORKDIR/$test_name/test.diff"
    [[ -f "$diff_file" ]] || continue
    echo "=== $test_name ==="
    cat "$diff_file"
    echo ""
done

# Summary.
PASS=0; FAIL=0; XFAIL=0; SKIP=0
for test_dir in "${tests[@]}"; do
    test_name=$(basename "$test_dir")
    status_file="$WORKDIR/$test_name.status"
    status=$([[ -f "$status_file" ]] && cat "$status_file" || echo "SKIP")
    case "$status" in
        PASS)  ((PASS++))  || true ;;
        FAIL)  ((FAIL++))  || true ;;
        XFAIL) ((XFAIL++)) || true ;;
        *)     ((SKIP++))  || true ;;
    esac
done

msg="Results: $PASS passed, $FAIL failed"
[[ $XFAIL -gt 0 ]] && msg="$msg, $XFAIL expected failures"
[[ $SKIP  -gt 0 ]] && msg="$msg, $SKIP skipped"
[[ $FAIL -eq 0 ]] && colorize "$msg" green || colorize "$msg" red

[[ $FAIL -eq 0 ]]
