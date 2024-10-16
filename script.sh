#!/bin/sh

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
TEMP_NODE_MODULES="${GITHUB_ACTION_PATH}/temp_node_modules"
mkdir -p "${TEMP_NODE_MODULES}"

echo '::group:: Installing ESLint and plugins in temporary directory...'

# Copy package.json and package-lock.json if they exist
cp "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}/package.json" "${TEMP_NODE_MODULES}/"
if [ -f "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}/package-lock.json" ]; then
  cp "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}/package-lock.json" "${TEMP_NODE_MODULES}/"
fi

# Install only devDependencies
cd "${TEMP_NODE_MODULES}" || exit 1
npm ci --only=dev
echo '::endgroup::'

# Add the temporary node_modules/.bin to PATH
export PATH="${TEMP_NODE_MODULES}/node_modules/.bin:${PATH}"

echo '::group:: Running ESLint with reviewdog 🐶 ...'
eslint_output=$(mktemp)
# Run ESLint with --resolve-plugins-relative-to pointing to the temp directory
eslint --resolve-plugins-relative-to "${TEMP_NODE_MODULES}" -f="${ESLINT_FORMATTER}" "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" > "$eslint_output"

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
