#!/bin/bash

setup(){
    echo "setup"
}

teardown(){
    echo "teardown"
}

jwt_encode(){
	data=${1?}
	echo -n "${data}" \
	| openssl base64 -e -A \
	| sed s/\+/-/ \
	| sed -E s/=+$//
}

jwt_sig(){
	data=${1?}
	secret=${2?}
	signature=$( \
		echo -n "${data}" \
		| openssl dgst -sha256 -hmac "${secret}" -binary \
		| openssl base64 -e -A \
		| sed s/\+/-/ \
		| sed -E s/=+$// \
	)
	echo -n "${data}"."${signature}"
}

jwt_token(){
	role=${1:-role}
	secret=${2:-test_secret}
	header="$(jwt_encode '{"alg":"HS256"}')"
	payload="$(jwt_encode '{"role":"'"${role}"'"}')"
	echo -n "$(jwt_sig "${header}.${payload}" "${secret}")"
}
