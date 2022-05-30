# Thank you BretFisher
# https://github.com/BretFisher/nodejs-rocks-in-docker

FROM node:16.14.2-slim as node
WORKDIR /app
COPY --chown=node:node package*.json yarn*.lock ./
RUN npm install
COPY --chown=node:node . .
RUN npm run \!build:tsc

FROM ubuntu:focal-20220404 as base
RUN apt-get update \
    && apt-get -qq install -y --no-install-recommends \
    tini \
    && rm -rf /var/lib/apt/lists/*
ENTRYPOINT ["/usr/bin/tini", "--"]

COPY --from=node /usr/local/include/ /usr/local/include/
COPY --from=node /usr/local/lib/ /usr/local/lib/
COPY --from=node /usr/local/bin/ /usr/local/bin/
RUN corepack disable && corepack enable

RUN groupadd --gid 1000 node \
    && useradd --uid 1000 --gid node --shell /bin/bash --create-home node \
    && mkdir /app \
    && chown -R node:node /app

FROM base as prod
WORKDIR /app
COPY --from=node /app/build /app/build
RUN chown -R node:node /app/build/*
USER node
COPY --chown=node:node package*.json yarn*.lock ./
RUN npm ci --only=production && npm cache clean --force
COPY --chown=node:node . .

CMD ["node", "./build/index.js"]
