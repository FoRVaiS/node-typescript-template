# Thank you BretFisher
# https://github.com/BretFisher/nodejs-rocks-in-docker

FROM node:16.14.2-slim as node
FROM ubuntu:focal-20220404 as base
RUN apt-get update \
    && apt-get -qq install -y --no-install-recommends \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Copy node binaries and libraries
COPY --from=node /usr/local/include/ /usr/local/include/
COPY --from=node /usr/local/lib/ /usr/local/lib/
COPY --from=node /usr/local/bin/ /usr/local/bin/
RUN corepack disable && corepack enable

# Create a non-privileged user and workspace
RUN groupadd --gid 1000 node \
    && useradd --uid 1000 --gid node --shell /bin/bash --create-home node \
    && mkdir /app \
    && chown -R node:node /app

WORKDIR /app
EXPOSE 8080

# Install production level dependencies
COPY --chown=node:node package*.json yarn*.lock ./
RUN npm ci --only=production && npm cache clean --force

# Run development (assume bind mount)
FROM base as dev
USER node
ENV NODE_ENV=development
RUN npm install && npm cache clean --force

# Build the project
# This project requires modules from dev dependencies as part of the build process
# so we have to import node_modules from the dev stage
FROM base as build
COPY --chown=node:node . .
COPY --from=dev --chown=node:node /app/node_modules/ /app/node_modules/
RUN rm -rf build/ \
    && npx tsc -p tsconfig.release.json \
    && npx tsc-alias -p tsconfig.release.json \ 
    && rm -rf node_modules/
COPY --from=base --chown=node:node /app/node_modules/ /app/node_modules/

# Run production
FROM build as prod
USER node
ENV NODE_ENV=production
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "./build"]