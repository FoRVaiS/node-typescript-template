PROJECT = node-typescript-template

COMPOSE_FILE = ./docker-compose.yml
COMPOSE = docker compose -p $(PROJECT) -f $(COMPOSE_FILE)

.PHONY: build run env dev prod

build:
	$(COMPOSE) build $(STAGE)

run:
	$(COMPOSE) run -it --rm --service-ports $(STAGE)

env:
	@make run STAGE=dev-container

dev:
	@make run STAGE=dev

prod:
	@make run STAGE=prod
