NAMESPACE ?= userdb
IMAGE_POSTGRES ?= postgres:latest
IMAGE_POSTGREST ?= postgrest/postgrest:v7.0.1@sha256:2a10713acc388f9a64320443e949eb87a0424ab280e68c4ed4a6d0653c001586

PSQL ?= psql

.PHONY: help
help:
	@echo "build             - compile/order all sql files to out directory"
	@echo "fetch             - fetch submodules"
	@echo "fetch-latest      - fetch submodules at latest upstream master refs"
	@echo "test              - run tests with in-place PostgreSQL"
	@echo "install           - Setup schemas on local system PostgreSQL"
	@echo "clean             - Delete generated files"
	@echo "develop           - Load schema into temp db and launch shell"
	@echo "docker-start      - Start service containers"
	@echo "docker-stop       - Stop service containers"
	@echo "docker-test       - run tests from a predictable test container"
	@echo "docker-test-build - build test container"
	@echo "docker-test-shell - run shell from a test container"

out/json-schemas.sql: schema/sql/json-schemas.sql
	mkdir -p $(@D)
	./scripts/build schema < "$<" > "$@"

.PHONY: build
build: out/json-schemas.sql

schema/ext/json-schema/%:
	git submodule update --init --recursive $(@D)

test/sql/plpgunit/%:
	git submodule update --init --recursive $(@D)

.PHONY: fetch
fetch: schema/ext/json-schema/ test/sql/plpgunit/

.PHONY: fetch-latest
fetch-latest:
	git submodule foreach 'git checkout master && git pull'

SCHEMA_FILES := \
	schema/sql/schema.sql \
	schema/sql/access.sql \
	schema/sql/api.sql \
	schema/sql/metrics.sql \
	schema/sql/nss.sql \
	schema/sql/reserved.sql \
	schema/sql/stats.sql \
	schema/ext/json-schema/postgres-json-schema--0.1.0.sql \
	out/json-schemas.sql

.PHONY: install
install: $(SCHEMA_FILES)
	$(PSQL) -v ON_ERROR_STOP=1 $(foreach file,$(SCHEMA_FILES),-f $(file));

.PHONY: test
test: \
	docker-test-build \
	docker-restart \
	docker-test \
	docker-stop

.PHONY: test-shell
test-shell: \
	docker-test-build \
	docker-restart \
	docker-test-shell \
	docker-stop

.PHONY: clean
clean:
	rm -rf out

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
		--env POSTGRES_PASSWORD=test_password \
		-p 5432:5432 \
		$(IMAGE_POSTGRES)
	## Wait for database to be up
	docker run \
		--rm \
		--network=$(NAMESPACE) \
		--env PGHOST=$(NAMESPACE)-postgres \
		--env PGUSER=postgres \
		--env PGPASSWORD=test_password \
		$(IMAGE_POSTGRES) sh -c 'until pg_isready; do sleep 1; done'
	# Load schema
	$(MAKE) \
		PSQL="docker run \
			--rm \
			--network=$(NAMESPACE) \
			--env PGHOST=$(NAMESPACE)-postgres \
			--env PGUSER=postgres \
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
		--env PGRST_DB_URI="postgres://postgres:test_password@$(NAMESPACE)-postgres/userdb" \
  		--env PGRST_DB_SCHEMA="v1" \
  		--env PGRST_DB_ANON_ROLE="api-anon" \
  		--env PGRST_JWT_SECRET="a_test_only_postgrest_jwt_secret" \
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

.PHONY: docker-test
docker-test: docker-stop docker-start docker-test-build
	docker run \
		-it \
		--rm \
		--hostname=$(NAMESPACE)-test \
		--name $(NAMESPACE)-test \
		--network=$(NAMESPACE) \
		--env PGHOST=$(NAMESPACE)-postgres \
		--env PGUSER=postgres \
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
		--env PGUSER=postgres \
		--env PGPASSWORD=test_password \
		local/$(NAMESPACE)-test \
		bash

.PHONY: docker-test-build
docker-test-build:
	docker build -t local/$(NAMESPACE)-test test/
