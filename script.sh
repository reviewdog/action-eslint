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

# Create a temporary directory for installing ESLint and plugins
TEMP_ESLINT_DIR="${GITHUB_ACTION_PATH}/temp_eslint"
mkdir -p "${TEMP_ESLINT_DIR}"

echo '::group:: Installing ESLint and plugins in temporary directory...'

# Copy package.json and package-lock.json to temporary directory
cp "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}/package.json" "${TEMP_ESLINT_DIR}/"
if [ -f "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}/package-lock.json" ]; then
  cp "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}/package-lock.json" "${TEMP_ESLINT_DIR}/"
fi

# Install only devDependencies
cd "${TEMP_ESLINT_DIR}" || exit 1
npm ci --only=dev
if [ $? -ne 0 ]; then
  echo "npm ci failed"
  exit 1
fi
echo '::endgroup::'

# Use npx to run ESLint
echo '::group:: Running ESLint with reviewdog 🐶 ...'
eslint_output=$(mktemp)

npx eslint --resolve-plugins-relative-to "${TEMP_ESLINT_DIR}" -f="${ESLINT_FORMATTER}" "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" > "$eslint_output"
eslint_exit_code=$?

# Check if ESLint execution was successful
if [ $eslint_exit_code -ne 0 ] && [ $eslint_exit_code -ne 1 ]; then
  echo "ESLint failed to run"
  cat "$eslint_output"
  exit $eslint_exit_code
fi

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
