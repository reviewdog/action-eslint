#!/bin/sh

cd "${GITHUB_ACTION_PATH}" || exit 1

TEMP_PATH="$(mktemp -d)"
export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"
ESLINT_FORMATTER="${GITHUB_ACTION_PATH}/eslint-formatter-rdjson/index.js"

echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

# DEBUG
pwd
ls -la .

echo '::group:: Running `npm install` to install eslint and plugins ...'
set -e
npm install --prefix "${GITHUB_ACTION_PATH}"
set +e
echo '::endgroup::'

export PATH="${GITHUB_ACTION_PATH}/.bin:${GITHUB_ACTION_PATH}/node_modules/.bin:$PATH"
# list all installed packages
npm list -g --depth=0

echo '::group:: Running eslint with reviewdog 🐶 ...'
eslint -f="${ESLINT_FORMATTER}" ${INPUT_ESLINT_FLAGS:-'.'} \
  | reviewdog -f=rdjson \
      -name="${INPUT_TOOL_NAME}" \
      -reporter="${INPUT_REPORTER:-github-pr-review}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" \
      -workdir="${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" \
      ${INPUT_REVIEWDOG_FLAGS} \
      "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}"

reviewdog_rc=$?
echo '::endgroup::'
exit $reviewdog_rc
