.DEFAULT_GOAL := update

up:
	docker-compose up -d

update:
	docker-compose down
	docker-compose pull
	docker-compose up --build -d

down:
	docker-compose down
