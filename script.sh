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
TEMP_ESLINT_DIR="${GITHUB_ACTION_PATH}/temp_eslint"
mkdir -p "${TEMP_ESLINT_DIR}"

echo '::group:: Installing ESLint and plugins in temporary directory...'

# Create a minimal package.json with ESLint and required plugins
cat > "${TEMP_ESLINT_DIR}/package.json" <<EOF
{
  "name": "eslint-action-temp",
  "version": "1.0.0",
  "private": true,
  "devDependencies": {
    "eslint": "^8.0.0",
    "eslint-plugin-react": "^7.0.0",
    "eslint-plugin-cypress": "^2.0.0"
    // Add other required plugins here
  }
}
EOF

# Install the devDependencies
cd "${TEMP_ESLINT_DIR}" || exit 1
npm install
echo '::endgroup::'

# Add the temporary node_modules/.bin to PATH
export PATH="${TEMP_ESLINT_DIR}/node_modules/.bin:${PATH}"

echo '::group:: Running ESLint with reviewdog 🐶 ...'
eslint_output=$(mktemp)

# Run ESLint with --resolve-plugins-relative-to pointing to the temp directory
eslint --resolve-plugins-relative-to "${TEMP_ESLINT_DIR}" -f="${ESLINT_FORMATTER}" "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" > "$eslint_output"

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
