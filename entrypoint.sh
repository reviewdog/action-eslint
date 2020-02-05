#!/bin/sh

cd "$GITHUB_WORKSPACE"

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

ESLINT_COMMAND="$(npm bin --prefix $INPUT_WORKDIR)/eslint"

if [ ! -f $ESLINT_COMMAND ]; then
  npm install --prefix $INPUT_WORKDIR
fi

eval $ESLINT_COMMAND --version

if [ "${INPUT_REPORTER}" == 'github-pr-review' ]; then
  # Use jq and github-pr-review reporter to format result to include link to rule page.
  eval $ESLINT_COMMAND --resolve-plugins-relative-to $INPUT_WORKDIR \
    -f="json" -c $INPUT_WORKDIR/.eslintrc.* ${INPUT_ESLINT_FLAGS:-$INPUT_WORKDIR} \
    | jq -r '.[] | {filePath: .filePath, messages: .messages[]} | "\(.filePath):\(.messages.line):\(.messages.column):\(.messages.message) [\(.messages.ruleId)](https://eslint.org/docs/rules/\(.messages.ruleId))"' \
    | reviewdog -efm="%f:%l:%c:%m" -name="eslint" -reporter=github-pr-review -level="${INPUT_LEVEL}"
else
  # github-pr-check,github-check (GitHub Check API) doesn't support markdown annotation.
  eval $ESLINT_COMMAND --resolve-plugins-relative-to $INPUT_WORKDIR \
    -f="stylish" -c $INPUT_WORKDIR/.eslintrc.* ${INPUT_ESLINT_FLAGS:-$INPUT_WORKDIR} \
    | reviewdog -f="eslint" -reporter="${INPUT_REPORTER:-github-pr-check}" -level="${INPUT_LEVEL}"
fi
