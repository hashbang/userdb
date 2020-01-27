load test_helper


@test "Can connect to userdb PostgreSQL" {
	sleep 1
	run pg_isready -U postgres -h userdb;
	[ "$status" -eq 0 ]
	echo "$output" | grep "accepting connections"
}

@test "Can connect to userdb PostgREST" {
	run curl http://userdb-postgrest:3000
	[ "$status" -eq 0 ]
	echo "$output" | grep "swagger"
}

@test "Cannot create user anonymously via PostgREST" {
	run curl http://userdb-postgrest:3000/passwd \
		-H "Content-Type:application/json" \
		-X POST \
		--data-binary @- <<-EOF
			{
				"name": "testuser",
				"host": "test.hashbang.sh",
				"data": {
					"shell": "/bin/bash",
					"ssh_keys": ["$(cat bats/keys/id_ed25519.pub)"]
				}
			}
			EOF
	[ "$status" -eq 0 ]
	echo "$output" | grep "permission denied"
}

@test "Can not create user with invalid host and valid auth via PostgREST" {

	run curl http://userdb-postgrest:3000/passwd \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $(jwt_token 'api-user-create')" \
		-X POST \
		--data-binary @- <<-EOF
			{
				"name": "testuser42",
				"host": "invalidbox.hashbang.sh",
				"data": {
					"shell": "/bin/bash",
					"ssh_keys": ["$(cat bats/keys/id_ed25519.pub)"]
				}
			}
			EOF
	[ "$status" -eq 0 ]
	echo "$output" | grep "violates foreign key constraint"
}

@test "Can create user with a valid host and valid auth via PostgREST" {

	run curl http://userdb-postgrest:3000/passwd \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $(jwt_token 'api-user-create')" \
		-X POST \
		--data-binary @- <<-EOF
			{
				"name": "testuser42",
				"host": "test.hashbang.sh",
				"data": {
					"shell": "/bin/bash",
					"ssh_keys": ["$(cat bats/keys/id_ed25519.pub)"]
				}
			}
			EOF
	[ "$status" -eq 0 ]

	run curl http://userdb-postgrest:3000/passwd?name=eq.testuser42
	echo "$output" | grep "testuser42"
}
