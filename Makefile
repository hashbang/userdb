SCHEMA_FILES= schema.sql stats.sql

.PHONY: help develop test install

help:
	@echo "test - run tests with in-place PostgreSQL"
	@echo "develop - Load schema into temporary postgres and launch shell"
	@echo "install - Setup schemas on local system PostgreSQL"


develop:
	./test.sh develop

test:
	./test.sh

install:
	createdb userdb
	@(foreach file,$(SCHEMA_FILES),psql -v ON_ERROR_STOP=1 -h localhost -d userdb -f $(file);)

