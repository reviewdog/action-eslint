#!/bin/sh

# Change directory to the action path
cd "${GITHUB_ACTION_PATH}" || exit 1

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"
ESLINT_FORMATTER="${GITHUB_ACTION_PATH}/eslint-formatter-rdjson/index.js"

echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
# Install reviewdog to the action's bin directory
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${GITHUB_ACTION_PATH}/bin"
echo '::endgroup::'

# Add reviewdog to PATH
export PATH="${GITHUB_ACTION_PATH}/bin:${PATH}"

echo '::group:: Installing ESLint and required plugins in the action directory...'
# Install ESLint and required plugins in the action's directory
npm install eslint eslint-plugin-react --prefix "${GITHUB_ACTION_PATH}" --no-save
echo '::endgroup::'

# Add action's node_modules binaries to PATH
export PATH="${GITHUB_ACTION_PATH}/node_modules/.bin:${PATH}"

echo '::group:: Running ESLint with reviewdog 🐶 ...'
eslint_output=$(mktemp)
# Run ESLint with --resolve-plugins-relative-to pointing to the action's directory
eslint --resolve-plugins-relative-to "${GITHUB_ACTION_PATH}" -f="${ESLINT_FORMATTER}" "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" > "$eslint_output"

# Change directory to your repository's workdir
cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit 1

# Use reviewdog from the action's bin directory
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
