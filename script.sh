#!/usr/bin/env bash

cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit 1

TEMP_PATH="$(mktemp -d)"
PATH="${TEMP_PATH}:$PATH"
export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"
ESLINT_FORMATTER="${GITHUB_ACTION_PATH}/eslint-formatter-rdjson/index.js"

echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

if ! npx --no-install -c 'eslint --version'; then
  echo '::group:: Running `npm install` to install eslint ...'
  npm install
  echo '::endgroup::'
fi

echo "eslint version:$(npx --no-install -c 'eslint --version')"

if [ "${INPUT_ONLY_CHANGED}" = "true" ]; then
  echo '::group:: Getting changed files list'

  if [ -z "${BASE_REF}" ] || [ -z "${HEAD_REF}" ]; then
    echo 'BASE_REF or HEAD_REF is not available. Running eslint on all files.'
  else
    if ! git cat-file -e "${BASE_REF}"; then
      git fetch --depth 1 origin "${BASE_REF}"
    fi

    CHANGED_FILES=()
    while IFS= read -r file; do
      CHANGED_FILES+=("${file}")
    done < <(git diff --relative --diff-filter=d --name-only "${BASE_REF}..${HEAD_REF}")

    if (( ${#CHANGED_FILES[@]} == 0 )); then
      echo 'No changed files, skipping'
      exit 0
    fi

    printf '%s\n' "${CHANGED_FILES[@]}"

    if (( ${#CHANGED_FILES[@]} > 100 )); then
      echo "More than 100 changed files (${#CHANGED_FILES[@]}), running eslint on all files"
      unset CHANGED_FILES
    fi
  fi

  echo '::endgroup::'
fi

# shellcheck disable=SC2206
ESLINT_FLAGS_ARRAY=( ${INPUT_ESLINT_FLAGS:-'.'} )

ESLINT_ARGS=(-f "${ESLINT_FORMATTER}")
ESLINT_ARGS+=("${ESLINT_FLAGS_ARRAY[@]}")
if [ -n "${CHANGED_FILES+x}" ]; then
  ESLINT_ARGS+=("${CHANGED_FILES[@]}")
fi

echo '::group:: Running eslint with reviewdog 🐶 ...'
# shellcheck disable=SC2086
npx --no-install eslint "${ESLINT_ARGS[@]}" \
  | reviewdog -f=rdjson \
      -name="${INPUT_TOOL_NAME}" \
      -reporter="${INPUT_REPORTER:-github-pr-review}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-level="${INPUT_FAIL_LEVEL}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" \
      ${INPUT_REVIEWDOG_FLAGS}

reviewdog_rc=$?
echo '::endgroup::'
exit $reviewdog_rc
