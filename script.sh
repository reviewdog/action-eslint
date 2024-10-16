#!/bin/bash

# Set up variables
export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"
ESLINT_FORMATTER="${GITHUB_ACTION_PATH}/eslint-formatter-rdjson/index.js"

# Install reviewdog
echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${GITHUB_ACTION_PATH}/bin"
echo '::endgroup::'

# Add reviewdog to PATH
export PATH="${GITHUB_ACTION_PATH}/bin:${PATH}"

echo '::group:: Copying package.json and package-lock.json to workdir...'
cp "${GITHUB_ACTION_PATH}/package.json" "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}/"
cp "${GITHUB_ACTION_PATH}/package-lock.json" "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}/"
echo '::endgroup::'

# Change directory to your repository's workdir
cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit 1

echo '::group:: Installing ESLint and plugins in workdir...'

# Install dependencies in the workdir
npm install
if [ $? -ne 0 ]; then
  echo "npm install failed"
  exit 1
fi
echo '::endgroup::'

# Use npx to run ESLint
echo '::group:: Running ESLint with reviewdog 🐶 ...'
eslint_output=$(mktemp)

npx eslint --resolve-plugins-relative-to "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" -f="${ESLINT_FORMATTER}" "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" > "$eslint_output"
eslint_exit_code=$?

# Check if ESLint execution was successful
if [ $eslint_exit_code -ne 0 ] && [ $eslint_exit_code -ne 1 ]; then
  echo "ESLint failed to run"
  cat "$eslint_output"
  exit $eslint_exit_code
fi

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
