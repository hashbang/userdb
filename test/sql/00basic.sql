-- -*- mode: sql; sql-product: postgres -*-

-- Basic operations populating the database.

CREATE FUNCTION unit_tests.create_hosts()
RETURNS test_result AS $$
DECLARE message test_result;
DECLARE result boolean;
DECLARE host_name text;
BEGIN
    insert into hosts (name, data) values ('testbox.hashbang.sh', '{
	"inet": ["192.0.2.4"],
	"coordinates": {
	    "lat": 0,
	    "lon": 0
	},
	"location": "NULL island",
	"maxUsers": 1000
     }'::jsonb) returning name INTO host_name;
    insert into hosts (name, data) values ('fo0.hashbang.sh', '{
	"inet": ["192.0.2.6"],
	"coordinates": {
	    "lat": 1,
	    "lon": 2
	},
	"location": "Disk Dr.",
	"maxUsers": 1000
     }'::jsonb);
    SELECT * FROM assert.is_equal(host_name,'testbox.hashbang.sh') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    RETURN assert.ok('End of test.');
END $$ LANGUAGE plpgsql;


CREATE FUNCTION unit_tests.create_groups()
RETURNS test_result AS $$
DECLARE message test_result;
DECLARE result boolean;
DECLARE group_gid integer;
BEGIN
    insert into "group" (gid, name) values (27, 'sudo') RETURNING gid INTO group_gid;
    SELECT * FROM assert.is_equal(group_gid, 27) INTO message, result;
    IF result = false THEN RETURN message; END IF;

    insert into "group" (gid, name) values (4, 'adm') RETURNING gid INTO group_gid;
    SELECT * FROM assert.is_equal(group_gid,  4) INTO message, result;
    IF result = false THEN RETURN message; END IF;

    RETURN assert.ok('End of test.');
END $$ LANGUAGE plpgsql;


CREATE FUNCTION unit_tests.create_users()
RETURNS test_result AS $$
DECLARE testbox integer;
DECLARE message test_result;
DECLARE result boolean;
DECLARE passwd_name text;
BEGIN
    insert into passwd (name, host, shell) values ('testuser', 'testbox.hashbang.sh', '/bin/nologin');
    insert into passwd (name, host, shell) values ('testuser2', 'testbox.hashbang.sh', '/bin/sh') returning name INTO passwd_name;
    SELECT * FROM assert.is_equal(passwd_name,'testuser2') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    RETURN assert.ok('End of test.');
END $$ LANGUAGE plpgsql;

CREATE FUNCTION unit_tests.add_user_to_group()
RETURNS test_result AS $$
DECLARE testbox integer;
DECLARE user_id integer;
DECLARE message test_result;
DECLARE result boolean;
DECLARE passwd_name text;
BEGIN
    insert into passwd (name, host, shell, data)
    values ('testadmin', 'fo0.hashbang.sh', '/bin/zsh', '{"name": "Just an admin."}')
    RETURNING uid INTO user_id;

    insert into aux_groups (uid, gid) values (user_id, 27); -- 27 is sudo
    insert into aux_groups (uid, gid) values (user_id,  4); --  4 is adm

    SELECT "name"
    FROM passwd JOIN aux_groups
    USING (uid) WHERE (gid = 27)
    INTO passwd_name;
    SELECT * FROM assert.is_equal(passwd_name,'testadmin') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    RETURN assert.ok('End of test.');
END $$ LANGUAGE plpgsql;

CREATE FUNCTION unit_tests.add_public_key_to_user()
RETURNS test_result AS $$
DECLARE testbox integer;
DECLARE key_fingerprint text;
DECLARE user_id integer;
DECLARE message test_result;
DECLARE result boolean;
DECLARE passwd_name text;
BEGIN
    select "uid" from passwd where name = 'testuser' into user_id;

    insert into ssh_public_key (type, key, comment, uid)
    values (
        'ssh-ed25519',
        'AAAAC3NzaC1lZDI1NTE5AAAAIKCXEbRyTwfQLhxpt9TMlpZSSGXNwnGmFdpV+yiljd4g',
        'Some key',
        user_id
    );

    SELECT "fingerprint"
    FROM passwd JOIN ssh_public_key
    USING (uid) WHERE (name = 'testuser')
    INTO key_fingerprint;
    SELECT * FROM assert.is_equal(
        key_fingerprint,
	'pGSl2PBDaMhaRiFqQiVTw5F3OWyiPg0uRMgZ2p3FfC0='
    ) INTO message, result;
    IF result = false THEN RETURN message; END IF;

    RETURN assert.ok('End of test.');
END $$ LANGUAGE plpgsql;
