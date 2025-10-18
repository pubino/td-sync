DOCKER_IMAGE ?= tiny-data-sync-test

.PHONY: test docker-build docker-run

docker-build:
	docker build -f docker/Dockerfile -t $(DOCKER_IMAGE) .

docker-run:
	docker run --rm -v $(PWD):/workspace $(DOCKER_IMAGE)

test: docker-build docker-run
