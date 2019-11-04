.DEFAULT_GOAL := update

up:
	docker-compose up -d

update:
	docker-compose pull
	docker-compose down
	docker-compose up --build -d

down:
	docker-compose down
