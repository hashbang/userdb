#!/bin/bash
set -e

run() {
    normal='\e[0m'
    yellow='\e[33m'
    printf "${yellow}%s${normal}\n" "$*" >&2
    "$@"
}

if ! command -v psql 2>/dev/null; then
    echo "No PostgreSQL utilities in PATH" >&2
    exit 1
fi

[ -n "${PGDATABASE+x}" ] || export PGDATABASE="userdb"
[ -n "${PGHOST+x}" ] || export PGHOST="localhost"
[ -n "${PGPORT+x}" ] || export PGPORT="5432"

psql="/usr/bin/psql --set ON_ERROR_STOP=1"

until pg_isready; do
	echo "Waiting on PostgreSQL to start..."
	sleep 1;
done;

for file in sql/plpgunit/install/1.install-unit-test.sql sql/*.sql; do
	run ${psql} -f "${file}"
done

run ${psql} -c "\
	BEGIN TRANSACTION; \
	SELECT * FROM unit_tests.begin();
	END TRANSACTION; \
"

run bats bats/test.bats
