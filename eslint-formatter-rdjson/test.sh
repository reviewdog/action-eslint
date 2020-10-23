#!/bin/bash
# Expected to run from the root repository.
set -eux
npx eslint ./testdata/*.js -f ./eslint-formatter-rdjson/index.js | jq . > eslint-formatter-rdjson/testdata/result.out
diff -u eslint-formatter-rdjson/testdata/result.*
