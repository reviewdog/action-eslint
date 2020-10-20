FROM node:current-alpine

ENV REVIEWDOG_VERSION=v0.10.1

# RUN wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh| sh -s -- -b /usr/local/bin/ ${REVIEWDOG_VERSION}
RUN wget -O - -q https://raw.githubusercontent.com/reviewdog/nightly/master/install.sh| sh -s -- -b /usr/local/bin/

RUN apk --no-cache add jq git

COPY entrypoint.sh /entrypoint.sh
COPY eslint-formatter-rdjson/index.js /formatter.js

ENTRYPOINT ["/entrypoint.sh"]
