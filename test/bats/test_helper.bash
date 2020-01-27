#!/bin/bash

setup(){
    psql -c "insert into hosts (name,maxusers) values ('test.hashbang.sh','500');";
}

teardown(){
    psql -c "delete from passwd;";
    psql -c "delete from hosts;";
}

base64_url_encode(){
	data=${1?}
	echo -n "${data}" \
	| openssl base64 -e -A \
	| sed 's/\+/-/g' \
	| sed 's/\//_/g' \
	| sed -E 's/=+$//'
}

jwt_sig(){
	data=${1?}
	secret=${2?}
	signature=$( \
		echo -n "${data}" \
		| openssl dgst -sha256 -hmac "${secret}" -binary \
		| openssl base64 -e -A \
		| sed 's/\+/-/g' \
		| sed 's/\//_/g' \
		| sed -E 's/=+$//'
	)
	echo -n "${data}"."${signature}"
}

jwt_token(){
	role=${1:-role}
	secret=${2:-a_test_only_postgrest_jwt_secret}
	header="$(base64_url_encode '{"alg":"HS256"}')"
	payload="$(base64_url_encode '{"role":"'"${role}"'"}')"
	echo -n "$(jwt_sig "${header}.${payload}" "${secret}")"
}
