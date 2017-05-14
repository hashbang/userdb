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
    insert into passwd (name, host, "data") values ('testuser', 'testbox.hashbang.sh', '{"ssh_keys": [], "shell": "/sbin/nologin"}'::jsonb);
    insert into passwd (name, host, "data") values ('testuser2', 'testbox.hashbang.sh', '{"ssh_keys": [], "shell": "/bin/sh"}'::jsonb) returning name INTO passwd_name;
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
    insert into passwd (name, host, "data")
    values ('testadmin', 'fo0.hashbang.sh',
    '{ "name":"Just an admin.", "ssh_keys": [], "shell": "/usr/bin/zsh" }'::jsonb)
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
