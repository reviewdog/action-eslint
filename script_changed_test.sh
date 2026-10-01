#!/usr/bin/env bash
# Exercise changed-file selection in the real entrypoint with a local repository.
set -eu
ROOT=$(cd "$(dirname "$0")" && pwd)
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT
mkdir -p "$TEST_DIR/bin" "$TEST_DIR/work"
cat > "$TEST_DIR/bin/curl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat > "$TEST_DIR/bin/npx" <<'EOF'
#!/usr/bin/env bash
if [ "$*" = "--no-install -c eslint --version" ]; then
  echo v10.4.1
else
  printf '%s\0' "$@" > "$ARGS_FILE"
fi
EOF
cat > "$TEST_DIR/bin/reviewdog" <<'EOF'
#!/usr/bin/env bash
cat >/dev/null
EOF
chmod +x "$TEST_DIR/bin/"*
export PATH="$TEST_DIR/bin:$PATH"
export GITHUB_WORKSPACE="$TEST_DIR/work" GITHUB_ACTION_PATH="$ROOT"
export INPUT_WORKDIR=. INPUT_ONLY_CHANGED=true INPUT_ESLINT_FLAGS=.
export ARGS_FILE="$TEST_DIR/args"
cd "$TEST_DIR/work"
git init -q
git config core.autocrlf false
git -c user.name=Test -c user.email=test@example.invalid commit --allow-empty -qm base
export BASE_REF=$(git rev-parse HEAD)
printf 'const value = 1;\n' > '日本語 file.js'
git add .
git -c user.name=Test -c user.email=test@example.invalid commit -qm change
export HEAD_REF=$(git rev-parse HEAD)

assert_args() {
  bash "$ROOT/script.sh" > "$TEST_DIR/output" 2>&1
  local -a actual=() expected=(--no-install eslint -f "$ROOT/eslint-formatter-rdjson/index.js" "$@")
  while IFS= read -r -d '' arg; do actual+=("$arg"); done < "$ARGS_FILE"
  if [ "${#actual[@]}" -ne "${#expected[@]}" ]; then
    printf 'Unexpected arguments: <%s>\n' "${actual[@]}" >&2
    exit 1
  fi
  for i in "${!expected[@]}"; do [ "${actual[$i]}" = "${expected[$i]}" ]; done
}
assert_args '日本語 file.js'
INPUT_ESLINT_FLAGS='' assert_args '日本語 file.js'
INPUT_ESLINT_FLAGS=--cache assert_args --cache '日本語 file.js'
INPUT_ONLY_CHANGED=false assert_args .
INPUT_ESLINT_FLAGS=src assert_args src '日本語 file.js'
rm "$ARGS_FILE"
BASE_REF="$HEAD_REF" bash "$ROOT/script.sh" > "$TEST_DIR/output" 2>&1
[ ! -e "$ARGS_FILE" ]
BASE_REF='' assert_args .
for i in {1..100}; do printf '\n' > "file-$i.js"; done
git add .
git -c user.name=Test -c user.email=test@example.invalid commit -qm 'many changes'
export HEAD_REF=$(git rev-parse HEAD)
assert_args .
BASE_REF=missing-commit bash "$ROOT/script.sh" > "$TEST_DIR/output" 2>&1 && exit 1
echo 'All changed-file entrypoint tests passed'
