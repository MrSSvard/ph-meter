build:
	docker pull grafana/grafana
	docker build . --tag zappka/phmeter
	docker tag zappka/phmeter:latest zappka/phmeter:$(shell date +%d-%m-%y)

push:
	docker push zappka/phmeter:latest
	docker push zappka/phmeter:$(shell date +%d-%m-%y)

all: build push
