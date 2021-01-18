NAMESPACE ?= userdb
POSTGRES_USER ?= postgres
POSTGRES_DB ?= postgres
IMAGE_POSTGRES ?= postgres:latest
IMAGE_POSTGREST ?= postgrest/postgrest:v7.0.1@sha256:2a10713acc388f9a64320443e949eb87a0424ab280e68c4ed4a6d0653c001586

.PHONY: docker-help
docker-help:
	@echo "docker-start       - Start service containers"
	@echo "docker-stop        - Stop service containers"
	@echo "docker-test        - run tests from a predictable test container"
	@echo "docker-test-build  - build test container"
	@echo "docker-test-shell  - run shell from a test container"
	@echo "docker-schema-dump - dump the schema of the database running in docker"

.PHONY: docker-restart
docker-restart: docker-stop docker-start

.PHONY: docker-start
docker-start:
	docker network inspect $(NAMESPACE) \
	|| docker network create $(NAMESPACE)
	# Start database
	docker inspect -f '{{.State.Running}}' $(NAMESPACE)-postgres 2>/dev/null \
	|| docker run  \
		--detach=true \
		--name=$(NAMESPACE)-postgres \
		--network=$(NAMESPACE) \
		--env POSTGRES_DB=$(POSTGRES_DB) \
		--env POSTGRES_USER=$(POSTGRES_USER) \
		--env POSTGRES_PASSWORD=test_password \
		-p 5432:5432 \
		$(IMAGE_POSTGRES)
	## Wait for database to be up
	docker run \
		--rm \
		--network=$(NAMESPACE) \
		--env PGHOST=$(NAMESPACE)-postgres \
		--env PGDATABASE=$(POSTGRES_DB) \
		--env PGUSER=$(POSTGRES_USER) \
		--env PGPASSWORD=test_password \
		$(IMAGE_POSTGRES) sh -c 'until pg_isready; do sleep 1; done'
	# Load schema
	$(MAKE) -f Makefile \
		PSQL="docker run \
			--rm \
			--network=$(NAMESPACE) \
			--env PGHOST=$(NAMESPACE)-postgres \
			--env PGDATABASE=$(POSTGRES_DB) \
			--env PGUSER=$(POSTGRES_USER) \
			--env PGPASSWORD=test_password \
			-v `pwd`:`pwd` \
			-w `pwd` \
			$(IMAGE_POSTGRES) psql" \
		install
	# Start web API
	docker inspect -f '{{.State.Running}}' $(NAMESPACE)-postgrest 2>/dev/null \
	|| docker run \
		--rm \
		--detach=true \
		--name $(NAMESPACE)-postgrest \
		--network=$(NAMESPACE) \
		--env PGRST_DB_URI="postgres://$(POSTGRES_USER):test_password@$(NAMESPACE)-postgres/$(POSTGRES_DB)" \
		--env PGRST_DB_SCHEMA="v1" \
		--env PGRST_DB_ANON_ROLE="api-anon" \
		--env PGRST_JWT_SECRET="a_test_only_postgrest_jwt_secret" \
		-p 3000:3000 \
		$(IMAGE_POSTGREST)

.PHONY: docker-stop
docker-stop:
	docker inspect -f '{{.State.Running}}' $(NAMESPACE)-postgres 2>/dev/null \
	&& docker rm -f $(NAMESPACE)-postgres || true
	docker inspect -f '{{.State.Running}}' $(NAMESPACE)-postgrest 2>/dev/null \
	&& docker rm -f $(NAMESPACE)-postgrest || true

.PHONY: docker-log
docker-log:
	docker logs -f $(NAMESPACE)-postgres

.PHONY: docker-schema-dump
docker-schema-dump:
	$(MAKE) -f Makefile \
		PG_DUMP="docker run \
			--rm \
			--network=$(NAMESPACE) \
			--env PGHOST=$(NAMESPACE)-postgres \
			--env PGDATABASE=$(POSTGRES_DB) \
			--env PGUSER=$(POSTGRES_USER) \
			--env PGPASSWORD=test_password \
			$(IMAGE_POSTGRES) pg_dump" \
		schema-dump.psql

.PHONY: docker-test
docker-test: docker-stop docker-start docker-test-build
	docker run \
		-it \
		--rm \
		--hostname=$(NAMESPACE)-test \
		--name $(NAMESPACE)-test \
		--network=$(NAMESPACE) \
		--env PGHOST=$(NAMESPACE)-postgres \
		--env PGDATABASE=$(POSTGRES_DB) \
		--env PGUSER=$(POSTGRES_USER) \
		--env PGPASSWORD=test_password \
		local/$(NAMESPACE)-test

.PHONY: docker-test-shell
docker-test-shell: docker-stop docker-start docker-test-build
	docker run \
		--rm \
		-it \
		--hostname=$(NAMESPACE)-test-shell \
		--name $(NAMESPACE)-test-shell \
		--network=$(NAMESPACE) \
		--env PGHOST=$(NAMESPACE)-postgres \
		--env PGDATABASE=$(POSTGRES_DB) \
		--env PGUSER=$(POSTGRES_USER) \
		--env PGPASSWORD=test_password \
		local/$(NAMESPACE)-test \
		bash

.PHONY: docker-test-build
docker-test-build:
	docker build -t local/$(NAMESPACE)-test test/
