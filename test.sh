#!/bin/sh -ex

if ! command -v initdb 2>/dev/null; then
    echo "No PostgreSQL utilities in PATH" >&2
    exit 1
fi

if [ ! -d /tmp/plpgunit ]; then
    git clone https://github.com/mixerp/plpgunit /tmp/plpgunit
fi

trap 'pg_ctl -D "${WORKDIR}" stop; rm -rf -- "${WORKDIR}"' EXIT
WORKDIR=$(mktemp -d)

initdb -D "${WORKDIR}"
pg_ctl -D "${WORKDIR}" start -w -o "          \
	-c unix_socket_directories=${WORKDIR} \
	-c listen_addresses=''                \
"

for file in /tmp/plpgunit/install/1.install-unit-test.sql schema.sql test.sql; do
    psql --set ON_ERROR_STOP=1 -h "${WORKDIR}" -d postgres -f "$file"
done