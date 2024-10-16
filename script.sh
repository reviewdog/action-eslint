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

echo "eslint version:$(npx --no-install -c 'eslint --version')"

echo '::group:: Running eslint with reviewdog 🐶 ...'
npx --no-install -c "eslint -f="${ESLINT_FORMATTER}" ${INPUT_ESLINT_FLAGS:-'.'}" \
  | reviewdog -f=rdjson \
      -name="${INPUT_TOOL_NAME}" \
      -reporter="${INPUT_REPORTER:-github-pr-review}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" \
      -tee \
      ${INPUT_REVIEWDOG_FLAGS}

reviewdog_rc=$?
echo '::endgroup::'
exit $reviewdog_rc
