#!/bin/sh -e

run() {
    normal='\e[0m'
    yellow='\e[33m'
    printf "${yellow}%s${normal}\n" "$*" >&2

    "$@"
}

# Some distros support multiple installed versions of PostgreSQL
if ! command -v initdb 2>/dev/null; then
    for dir in /usr/lib/postgresql/*; do
	export PATH="${dir}/bin:${PATH}"
    done
fi

if ! command -v initdb 2>/dev/null; then
    echo "No PostgreSQL utilities in PATH" >&2
    exit 1
fi

run git submodule update

trap 'pg_ctl -D "${WORKDIR}" stop; rm -rf -- "${WORKDIR}"' EXIT
WORKDIR=$(mktemp -d)

run initdb -D "${WORKDIR}"
run pg_ctl -D "${WORKDIR}" start -w -o "      \
	-c unix_socket_directories=${WORKDIR} \
	-c listen_addresses=''                \
"


PSQL="psql --set ON_ERROR_STOP=1 -h ${WORKDIR} -d postgres"

for file in schema.sql stats.sql                             \
            postgres-json-schema/postgres-json-schema--*.sql \
            json-schemas.sql.tmp; do
    run ${PSQL} -f "$file"
done

for file in tests/plpgunit/install/1.install-unit-test.sql tests/*.sql; do
    run ${PSQL} -f "$file"
done

run ${PSQL} -c 'SELECT * FROM unit_tests.begin();' | tee "${WORKDIR}/log"

if [ "$1" != 'develop' ]; then
    grep -q 'Failed tests *: 0.' "${WORKDIR}/log"
else
    if command -v pgcli >/dev/null; then
	run pgcli -h "${WORKDIR}" -d postgres
    else
	run psql -h "${WORKDIR}" -d postgres
    fi
fi
