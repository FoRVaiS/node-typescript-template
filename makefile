app_name = node-typescript-template

go_dev: up_dev start_dev
	docker exec -it $(app_name) /bin/bash

start_dev:
	docker start $(app_name)

stop_dev:
	docker stop $(app_name)

up_dev:
	docker compose up -d

down_dev:
	docker compose down
