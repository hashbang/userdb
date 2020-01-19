PGDATABASE ?= userdb

.PHONY: help
help:
	@echo "build   - compile/order all sql files to out directory"
	@echo "test    - run tests with in-place PostgreSQL"
	@echo "develop - Load schema into temporary postgres and launch shell"
	@echo "install - Setup schemas on local system PostgreSQL"
	@echo "clean   - Delete generated files"


.PHONY: build
build: clean
	./scripts/build schema/ out/

.PHONY: install
install:
	createdb userdb
	$(foreach file,
		$(wildcard out/*.sql),
		psql -v ON_ERROR_STOP=1 -d userdb -f $(file);
	)

.PHONY: develop
develop:
	./scripts/test.sh develop

.PHONY: test
test:
	./scripts/test.sh

.PHONY: clean
clean:
	rm -rf out

.PHONY: docker-build
docker-build:
	docker build -t local/userdb:latest .

.PHONY: docker-run
docker-run: docker-build
	docker run -it \
		-e API_PASSWORD='derp' \
		-e POSTGRES_PASSWORD=password \
		-p 5432:5432 local/userdb

.PHONY: docker-test
docker-test: docker-run
