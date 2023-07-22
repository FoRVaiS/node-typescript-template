# Thank you BretFisher
# https://github.com/BretFisher/nodejs-rocks-in-docker

FROM node:18.17.0-slim as node
FROM ubuntu:focal-20220404 as base

ARG USER=node
ARG WORKSPACE=/app

RUN apt-get update \
    && apt-get -qq install -y --no-install-recommends \
    tini

# Copy node binaries and libraries
COPY --from=node /usr/local/include/ /usr/local/include/
COPY --from=node /usr/local/lib/ /usr/local/lib/
COPY --from=node /usr/local/bin/ /usr/local/bin/

# Create a non-privileged user and workspace
RUN groupadd --gid 1000 ${USER} \
    && useradd --uid 1000 --gid ${USER} --shell /bin/bash --create-home ${USER} \
    && mkdir ${WORKSPACE} \
    && chown -R ${USER}:${USER} ${WORKSPACE}

WORKDIR ${WORKSPACE}


# Install production level dependencies
COPY --chown=${USER}:${USER} package*.json yarn*.lock ./
USER ${USER}
RUN npm install --omit=dev && npm cache clean --force


# Run development
FROM base as dev
ENV NODE_ENV=development
USER ${USER}
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
    && usermod -aG sudo ${USER} \
    && echo "${USER} ALL=(ALL:ALL) NOPASSWD: ALL" | sudo EDITOR='tee -a' visudo \
    && npm install -g npm-check-updates \
    && npm cache clean --force
USER ${USER}
CMD ["bash"]


# Copy the entire project into the container
FROM base as source
COPY --chown=${USER}:${USER} . .


# Build the project
# This project requires modules from dev dependencies as part of the build process
# so we have to import node_modules from the dev stage
FROM source as build
COPY --from=dev --chown=${USER}:${USER} ${WORKSPACE}/node_modules/ ${WORKSPACE}/node_modules/
RUN rm -rf build/ \
    && npx tsc -p tsconfig.release.json \
    && npx tsc-alias -p tsconfig.release.json \
    && rm -rf node_modules/
COPY --from=base --chown=${USER}:${USER} ${WORKSPACE}/node_modules/ ${WORKSPACE}/node_modules/


# Run production
FROM build as prod
USER root
RUN rm -rf /var/lib/apt/lists/*
ENV NODE_ENV=production
USER ${USER}
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "./build"]
