.PHONY: help setup-hooks cz-commit cz-bump lint build build-carbon test publish

IMAGE_NAME ?= dildo-docker
IMAGE_VERSION ?= $(shell git describe --tags --always 2>/dev/null || echo dev)

help:
	@echo "Available targets:"
	@echo "  setup-hooks   Install pre-commit hooks locally"
	@echo "  cz-commit     Commit changes using commitizen interactive prompt"
	@echo "  cz-bump       Bump version and update CHANGELOG.md"
	@echo "  lint          Validate pre-commit configuration and files"
	@echo "  build         Build local Silicon container image"
	@echo "  build-carbon  Build local Carbon container image"
	@echo "  test          Run local verification test on the Silicon container"
	@echo "  publish       Push container images to registry"

setup-hooks:
	pre-commit install --hook-type commit-msg
	pre-commit install

cz-commit:
	cz commit

cz-bump:
	cz bump

lint:
	pre-commit run --all-files

build:
	docker build --build-arg IMAGE_VERSION=$(IMAGE_VERSION) -t $(IMAGE_NAME):silicon -f Dockerfile .

build-carbon:
	docker build --build-arg IMAGE_VERSION=$(IMAGE_VERSION) -t $(IMAGE_NAME):carbon -f Dockerfile.carbon .

test: build
	docker run --rm $(IMAGE_NAME):silicon --help

publish: build build-carbon
	docker push $(IMAGE_NAME):silicon
	docker push $(IMAGE_NAME):carbon
