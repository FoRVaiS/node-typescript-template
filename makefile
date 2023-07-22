PROJECT = node-typescript-template

COMPOSE_FILE = ./docker-compose.yml
COMPOSE = docker compose -p $(PROJECT) -f $(COMPOSE_FILE)

.PHONY: build run env dev prod

build:
	$(COMPOSE) build $(STAGE)

run:
	$(COMPOSE) run -it --rm --service-ports $(STAGE)

env:
	@make run STAGE=node-typescript-template-dev-container

dev:
	@make run STAGE=node-typescript-template-dev

prod:
	@make run STAGE=node-typescript-template-prod
