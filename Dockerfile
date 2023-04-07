# Thank you BretFisher
# https://github.com/BretFisher/nodejs-rocks-in-docker

FROM node:18.15.0-slim as node
FROM ubuntu:focal-20220404 as base
RUN apt-get update \
    && apt-get -qq install -y --no-install-recommends \
    tini

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
RUN npm install --omit=dev && npm cache clean --force


# Run development
FROM base as dev
ENV NODE_ENV=development
USER node
RUN npm install && npm cache clean --force
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["npm", "run", "start:dev"]


# Run development container
FROM dev as dev-container
USER root
RUN apt-get update \
    && apt-get -qq upgrade -y --no-install-recommends \
    # Enables git integration in vscode
    # No git support for non-vscode users due to lack of SSH and GPG support in this particular project
    git \
    # Enables passwordless sudo in the dev container
    sudo \
    && usermod -aG sudo node \
    && echo "node ALL=(ALL:ALL) NOPASSWD: ALL" | sudo EDITOR='tee -a' visudo \
    && npm install -g npm-check-updates \
    && npm cache clean --force
USER node
CMD ["bash"]


# Copy the entire project into the container
FROM base as source
COPY --chown=node:node . .

# Build the project
# This project requires modules from dev dependencies as part of the build process
# so we have to import node_modules from the dev stage
FROM source as build
COPY --from=dev --chown=node:node /app/node_modules/ /app/node_modules/
RUN rm -rf build/ \
    && npx tsc -p tsconfig.release.json \
    && npx tsc-alias -p tsconfig.release.json \
    && rm -rf node_modules/
COPY --from=base --chown=node:node /app/node_modules/ /app/node_modules/

# Run production
FROM build as prod
RUN rm -rf /var/lib/apt/lists/*
ENV NODE_ENV=production
USER node
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "./build"]
