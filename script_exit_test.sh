#!/usr/bin/env bash
# Exercise the real entrypoint without network or GitHub credentials.
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
  exit "${VERSION_RC:-0}"
fi
echo '{"diagnostics":[]}'
exit "${ESLINT_RC:-0}"
EOF
cat > "$TEST_DIR/bin/npm" <<'EOF'
#!/usr/bin/env bash
exit "${INSTALL_RC:-0}"
EOF
cat > "$TEST_DIR/bin/reviewdog" <<'EOF'
#!/usr/bin/env bash
cat >/dev/null
exit "${REVIEWDOG_RC:-0}"
EOF
chmod +x "$TEST_DIR/bin/"*
export PATH="$TEST_DIR/bin:$PATH"
export GITHUB_WORKSPACE="$TEST_DIR/work" GITHUB_ACTION_PATH="$ROOT"
export INPUT_WORKDIR=. INPUT_ONLY_CHANGED=false INPUT_ESLINT_FLAGS=.

assert_exit() {
  local expected=$1 actual=0
  bash "$ROOT/script.sh" > "$TEST_DIR/output" 2>&1 || actual=$?
  if [ "$actual" -ne "$expected" ]; then
    cat "$TEST_DIR/output"
    echo "Expected exit $expected, got $actual" >&2
    exit 1
  fi
}

ESLINT_RC=0 REVIEWDOG_RC=0 assert_exit 0
ESLINT_RC=1 REVIEWDOG_RC=0 assert_exit 0
ESLINT_RC=1 REVIEWDOG_RC=1 assert_exit 1
ESLINT_RC=0 REVIEWDOG_RC=1 assert_exit 1
ESLINT_RC=2 REVIEWDOG_RC=0 assert_exit 2
ESLINT_RC=127 REVIEWDOG_RC=0 assert_exit 127
VERSION_RC=1 INSTALL_RC=17 assert_exit 17
echo 'All entrypoint exit-status tests passed'
