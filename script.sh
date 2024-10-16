#!/bin/sh

# Change directory to the action path
cd "${GITHUB_ACTION_PATH}" || exit 1

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"
ESLINT_FORMATTER="${GITHUB_ACTION_PATH}/eslint-formatter-rdjson/index.js"

echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
# Install reviewdog to a known directory
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${GITHUB_ACTION_PATH}/bin"
echo '::endgroup::'

# Add reviewdog to PATH
export PATH="${GITHUB_ACTION_PATH}/bin:${PATH}"

echo '::group:: Running `npm install` to install ESLint and plugins ...'
set -e
# Change directory to your repository's workdir
cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit 1
# Install ESLint and all required plugins specified in your .eslintrc.js
npm install eslint eslint-plugin-react --no-save
set +e
echo '::endgroup::'

# Add node_modules binaries to PATH
export PATH="${GITHUB_WORKSPACE}/${INPUT_WORKDIR}/node_modules/.bin:${PATH}"

echo '::group:: Running ESLint with reviewdog 🐶 ...'
eslint_output=$(mktemp)
# Run ESLint using the formatter
eslint -f="${ESLINT_FORMATTER}" "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" > "$eslint_output"

# Use reviewdog from PATH
cat "$eslint_output" | reviewdog -f=rdjson \
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
