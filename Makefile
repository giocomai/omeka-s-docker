#Defaults
include .env
export #exports the .env variables

#Set DOCKER_IMAGE_VERSION in the .env file OR by passing in
PROJECT_NAME ?= tul_omeka-s
VERSION ?= $(DOCKER_IMAGE_VERSION)
IMAGE ?= tulibraries/$(PROJECT_NAME)
HARBOR ?= harbor.k8s.temple.edu
CLEAR_CACHES ?= no
CI ?= false
OMEKA_DB_HOST ?= db
OMEKA_DB_NAME ?= omeka
OMEKA_DB_USER ?= omeka
OMEKA_DB_PASSWORD ?= omeka
MARIADB_ROOT_PASSWORD ?= omeka

DEFAULT_RUN_ARGS ?= -e "EXECJS_RUNTIME=Disabled" \
    -e "K8=yes" \
    -e "OMEKA_DB_HOST=$(OMEKA_DB_HOST)" \
    -e "OMEKA_DB_NAME=$(OMEKA_DB_NAME)" \
    -e "OMEKA_DB_USER=$(OMEKA_DB_USER)" \
    -e "OMEKA_DB_PASSWORD=$(OMEKA_DB_PASSWORD)" \
    --rm -it

showenv:
	@echo $(OMEKA_DB_HOST)
	@echo $(OMEKA_DB_NAME)
	@echo $(OMEKA_DB_USER)

build: pull_db build_app

build_app:
	@docker build \
		--tag $(HARBOR)/$(IMAGE):$(VERSION) \
		--tag $(HARBOR)/$(IMAGE):latest \
		--file .docker/app/Dockerfile \
		--no-cache .

build_dev:
	@docker build --build-arg RAILS_MASTER_KEY=$(RAILS_MASTER_KEY) \
		--tag $(IMAGE):$(VERSION)-dev \
		--tag $(IMAGE):dev \
		--file .docker/app/Dockerfile.dev \
		--no-cache .

pull_db:
	@docker pull bitnami/mariadb:latest

up: run_db run_app

run_app:
	@docker run --name=$(PROJECT_NAME) -d -p 127.0.0.1:80:80/tcp \
		$(DEFAULT_RUN_ARGS) \
		$(HARBOR)/$(IMAGE):$(VERSION)

run_dev:
	@docker run --name=$(PROJECT_NAME)-dev -d -p 127.0.0.1:3000:3000/tcp \
		$(DEFAULT_RUN_ARGS) \
		--mount type=bind,source=$(shell basename $(CURDIR)),target=/app \
		$(IMAGE):dev sleep infinity

run_db:
	@docker run --name=db -d -p 127.0.0.1:3306:3306 \
	  -e MARIADB_ROOT_PASSWORD=omeka \
    -e MARIADB_DATABASE=omeka \
    -e MARIADB_USER=omeka \
    -e MARIADB_PASSWORD=omeka \
		bitnami/mariadb:latest

shell_app:
	@docker exec -it $(PROJECT_NAME) bash -l

shell_dev:
	@docker exec -it $(PROJECT_NAME)-dev bash -l

shell_db:
	@docker exec -it db bash -l

stop_dev:
	@docker stop $(PROJECT_NAME)-dev

start: start_db run_app

start_app:
	@docker start $(PROJECT_NAME)

start_db:
	@docker start db 

stop: stop_app stop_db

stop_app:
	@docker stop $(PROJECT_NAME)

stop_db:
	@docker stop db 

down: down_app down_db 

down_app:
	@docker stop $(PROJECT_NAME)

down_db:
	@docker stop db 
	@docker rm db 

lint:
	@if [ $(CI) == false ]; \
		then \
			hadolint .docker/app/Dockerfile; \
		fi

shell:
	@docker run --rm -it \
		$(DEFAULT_RUN_ARGS) \
		--entrypoint=sh --user=root \
		$(HARBOR)/$(IMAGE):$(VERSION)

scan:
	@if [ $(CLEAR_CACHES) == yes ]; \
		then \
			trivy image -c $(HARBOR)/$(IMAGE):$(VERSION); \
		fi
	@if [ $(CI) == false ]; \
		then \
			trivy $(HARBOR)/$(IMAGE):$(VERSION); \
		fi

deploy: scan lint
	@docker push $(HARBOR)/$(IMAGE):$(VERSION) \
	# This "if" statement needs to be a one liner or it will fail.
	# Do not edit indentation
	@if [ $(VERSION) != latest ]; \
		then \
			docker push $(HARBOR)/$(IMAGE):latest; \
		fi
