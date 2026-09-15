#!/usr/bin/env bash
# Tests for how script.sh parses INPUT_ESLINT_FLAGS into an argument array.
#
# The value of eslint_flags is a single string that may contain quoted
# arguments (for example globs such as "src/**/*.{ts,tsx}"). It must be split
# into arguments the same way a shell command line would be, with quote
# removal, so eslint receives the intended patterns rather than literal quote
# characters (see https://github.com/reviewdog/action-eslint/issues/271).
set -u

# parse_eslint_flags mirrors the parsing done in script.sh. Keep it in sync.
parse_eslint_flags() {
  # shellcheck disable=SC2294
  eval "ESLINT_FLAGS_ARRAY=( ${INPUT_ESLINT_FLAGS:-'.'} )"
}

fail_count=0

# assert_flags <description> <expected-count> <expected-elem...>
# Reads INPUT_ESLINT_FLAGS from the environment, parses it, and compares the
# resulting array against the expected elements.
assert_flags() {
  local desc="$1"
  shift
  local -a expected=("$@")

  parse_eslint_flags

  local ok=1
  if [ "${#ESLINT_FLAGS_ARRAY[@]}" -ne "${#expected[@]}" ]; then
    ok=0
  else
    local i
    for i in "${!expected[@]}"; do
      if [ "${ESLINT_FLAGS_ARRAY[$i]}" != "${expected[$i]}" ]; then
        ok=0
        break
      fi
    done
  fi

  if [ "${ok}" -eq 1 ]; then
    echo "ok - ${desc}"
  else
    echo "FAIL - ${desc}"
    echo "  input:    [${INPUT_ESLINT_FLAGS-<unset>}]"
    echo "  expected: (${#expected[@]}) $(printf '<%s> ' "${expected[@]}")"
    echo "  actual:   (${#ESLINT_FLAGS_ARRAY[@]}) $(printf '<%s> ' "${ESLINT_FLAGS_ARRAY[@]}")"
    fail_count=$((fail_count + 1))
  fi
}

# Plain unquoted value.
INPUT_ESLINT_FLAGS="testdata/" \
  assert_flags "plain directory" "testdata/"

# Flags plus a directory.
INPUT_ESLINT_FLAGS="testdata/ --ignore-pattern /test-subproject/" \
  assert_flags "flags and directory" "testdata/" "--ignore-pattern" "/test-subproject/"

# Quoted glob with braces must have its quotes stripped (issue #271).
INPUT_ESLINT_FLAGS='"src/**/*.{ts,tsx}"' \
  assert_flags "single quoted brace glob" 'src/**/*.{ts,tsx}'

# Multiple quoted globs.
INPUT_ESLINT_FLAGS='"src/**/*.{ts,tsx}" "integration/**/*.ts"' \
  assert_flags "multiple quoted globs" 'src/**/*.{ts,tsx}' 'integration/**/*.ts'

# Single-quoted argument containing a space stays a single argument.
INPUT_ESLINT_FLAGS="'dir with space/'" \
  assert_flags "single-quoted path with space" 'dir with space/'

# Empty value falls back to the current directory.
INPUT_ESLINT_FLAGS="" \
  assert_flags "empty falls back to ." "."

if [ "${fail_count}" -ne 0 ]; then
  echo "${fail_count} test(s) failed"
  exit 1
fi

echo "All tests passed"
