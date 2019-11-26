.DEFAULT_GOAL := update

up:
	docker-compose up -d

update:
	docker-compose pull
	docker-compose build
	docker-compose down
	docker-compose up -d

down:
	docker-compose down
