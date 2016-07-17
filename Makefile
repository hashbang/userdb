test:
	-(rm -rf /tmp/pg_test)
	initdb -D /tmp/pg_test
	pg_ctl -D /tmp/pg_test start -o "-c unix_socket_directories=/tmp/pg_test"
	-(git clone https://github.com/mixerp/plpgunit /tmp/plpgunit)
	-( psql -v ON_ERROR_STOP=1 -h /tmp/pg_test -d postgres \
		-f /tmp/plpgunit/install/1.install-unit-test.sql && \
	   psql -v ON_ERROR_STOP=1 -h /tmp/pg_test -d postgres -f schema.sql &&\
	   psql -v ON_ERROR_STOP=1 -h /tmp/pg_test -d postgres -f test.sql;\
	   echo $$? > /tmp/pg_test/exit_code )
	pg_ctl -D /tmp/pg_test stop
	exit $$(cat /tmp/pg_test/exit_code)

.PHONY: test
