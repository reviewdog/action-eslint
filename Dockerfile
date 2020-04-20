FROM node:current-alpine

ENV REVIEWDOG_VERSION=v0.9.17

RUN wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh| sh -s -- -b /usr/local/bin/ ${REVIEWDOG_VERSION}
RUN apk --no-cache add jq git

WORKDIR /
ENV PATH $PATH:/node_modules/.bin
COPY package.json package-lock.json /
RUN npm ci

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
