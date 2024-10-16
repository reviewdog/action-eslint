#!/bin/sh

cd "${GITHUB_ACTION_PATH}" || exit 1

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"
ESLINT_FORMATTER="${GITHUB_ACTION_PATH}/eslint-formatter-rdjson/index.js"

echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s
echo '::endgroup::'

echo '::group:: Running `npm install` to install eslint and plugins ...'
set -e
npm install --prefix "${GITHUB_ACTION_PATH}"
set +e
echo '::endgroup::'

export PATH="${GITHUB_ACTION_PATH}/.bin:${GITHUB_ACTION_PATH}/node_modules/.bin:$PATH"

echo '::group:: Running eslint with reviewdog 🐶 ...'
eslint_output=$(mktemp)
eslint -f="${ESLINT_FORMATTER}" "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" > "$eslint_output"

cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit 1
cat "$eslint_output" | ./bin/reviewdog -f=rdjson \
      -name="${INPUT_TOOL_NAME}" \
      -reporter="${INPUT_REPORTER:-github-pr-review}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" \
      ${INPUT_REVIEWDOG_FLAGS}

rm "$eslint_output"

reviewdog_rc=$?
echo '::endgroup::'
exit $reviewdog_rc
