#!/bin/sh

cd "$GITHUB_WORKSPACE"

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

if [ ! -f "$(npm bin)/eslint" ]; then
  npm install
fi

$(npm bin)/eslint --version

$(npm bin)/eslint -f="json" "${INPUT_ESLINT_FLAGS:-'.'}" \
 | jq -r '.[] | {filePath: .filePath, messages: .messages[]} | "\(.filePath):\(.messages.line):\(.messages.column):\(.messages.message) [\(.messages.ruleId)](https://eslint.org/docs/rules/\(.messages.ruleId))"' \
 | reviewdog -efm="%f:%l:%c:%m" -name="eslint" -reporter=github-pr-review -level="${INPUT_LEVEL}"
