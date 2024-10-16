#!/bin/sh

cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit 1

TEMP_PATH="$(mktemp -d)"
PATH="${TEMP_PATH}:$PATH"
export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"
ESLINT_FORMATTER="${GITHUB_ACTION_PATH}/eslint-formatter-rdjson/index.js"

echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

if ! command -v eslint &> /dev/null; then
  echo '::group:: Running `npm install` to install eslint ...'
  set -e
  npm install --prefix "${GITHUB_ACTION_PATH}"
  set +e
  echo '::endgroup::'
fi

NPM_PATH="${GITHUB_ACTION_PATH}/node_modules/.bin"

echo "eslint version: $(eslint --version)"

echo '::group:: Running eslint with reviewdog 🐶 ...'
npx --no-install -c "$NPM_PATH/eslint -f="${ESLINT_FORMATTER}" ${INPUT_ESLINT_FLAGS:-'.'}" \
  | reviewdog -f=rdjson \
      -name="${INPUT_TOOL_NAME}" \
      -reporter="${INPUT_REPORTER:-github-pr-review}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" \
      ${INPUT_REVIEWDOG_FLAGS}

reviewdog_rc=$?
echo '::endgroup::'
exit $reviewdog_rc
