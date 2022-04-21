FROM node:lts-alpine

WORKDIR /app
COPY . /app

RUN npm install
RUN npm run build
RUN rm -rf src
RUN npm prune --production

ENV NODE_ENV=PRODUCTION

CMD ["npm", "run-script", "!start:docker"]
