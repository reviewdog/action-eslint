#!/bin/bash
# Expected to run from the root repository.
set -eux
CWD=$(pwd)
npx eslint ./testdata/*.js -f ./eslint-formatter-rdjson/index.js \
  | jq . \
  | sed -e "s!${CWD}/!!g" \
  > eslint-formatter-rdjson/testdata/result.out
diff -u eslint-formatter-rdjson/testdata/result.*
