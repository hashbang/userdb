#!/bin/sh -ex

if ! command -v initdb 2>/dev/null; then
    echo "No PostgreSQL utilities in PATH" >&2
    exit 1
fi

git submodule update

trap 'pg_ctl -D "${WORKDIR}" stop; rm -rf -- "${WORKDIR}"' EXIT
WORKDIR=$(mktemp -d)

initdb -D "${WORKDIR}"
pg_ctl -D "${WORKDIR}" start -w -o "          \
	-c unix_socket_directories=${WORKDIR} \
	-c listen_addresses=''                \
"


PSQL="psql --set ON_ERROR_STOP=1 -h ${WORKDIR} -d postgres"

${PSQL} -f schema.sql

if [ "$1" = 'develop' ]; then
    psql -h "${WORKDIR}" -d postgres
else
    for file in tests/plpgunit/install/1.install-unit-test.sql tests/*.sql
    do
	${PSQL} -f "$file"
    done

    ${PSQL} -c 'SELECT * FROM unit_tests.begin();' | tee "${WORKDIR}/log"
    grep -q 'Failed tests *: 0.' "${WORKDIR}/log"
fi
