SCHEMA_FILES := schema.sql stats.sql reserved.sql               \
	$(wildcard postgres-json-schema/postgres-json-schema--*.sql)  \
	json-schemas.sql.tmp
YAML_FILES := $(wildcard schemas/data_*.yml)
RESERVED_NAMES := $(wildcard reserved/*)

PGDATABASE ?= userdb

.PHONY: help develop test install clean

help:
	@echo "test    - run tests with in-place PostgreSQL"
	@echo "develop - Load schema into temporary postgres and launch shell"
	@echo "install - Setup schemas on local system PostgreSQL"
	@echo "clean   - Delete generated files"


develop: $(SCHEMA_FILES)
	./test.sh develop

test:    $(SCHEMA_FILES)
	./test.sh

install: $(SCHEMA_FILES) $(RESERVED_NAMES)
	createdb '$(PGDATABASE)'
	$(foreach file,$(SCHEMA_FILES),psql -v ON_ERROR_STOP=1 -d '$(PGDATABASE)' -f $(file);)


json-schemas.sql.tmp: json-schemas.py json-schemas.sql $(YAML_FILES)
	./$<

clean:
	rm -f json-schemas.sql.tmp
