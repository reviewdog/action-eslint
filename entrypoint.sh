#!/bin/sh

cd "$GITHUB_WORKSPACE"

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit 1

if [ ! -f "$(npm bin)/eslint" ]; then
  npm install
fi

$(npm bin)/eslint --version

if [ "${INPUT_REPORTER}" == 'github-pr-review' ]; then
  # Use jq and github-pr-review reporter to format result to include link to rule page.
  $(npm bin)/eslint -f="json" ${INPUT_ESLINT_FLAGS:-'.'} \
    | jq -r '.[] | {filePath: .filePath, messages: .messages[]} | "\(.filePath):\(.messages.line):\(.messages.column):\(.messages.message) [\(.messages.ruleId)](https://eslint.org/docs/rules/\(.messages.ruleId))"' \
    | reviewdog -efm="%f:%l:%c:%m" -name="eslint" -reporter=github-pr-review -level="${INPUT_LEVEL}"
else
  # github-pr-check,github-check (GitHub Check API) doesn't support markdown annotation.
  $(npm bin)/eslint -f="stylish" ${INPUT_ESLINT_FLAGS:-'.'} \
    | reviewdog -f="eslint" -reporter="${INPUT_REPORTER:-github-pr-check}" -level="${INPUT_LEVEL}"
fi
