-- -*- mode: sql; product: postgres -*-

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
    SELECT * FROM assert.is_equal(host_name,'testbox.hashbang.sh') INTO message, result;

    IF result = false THEN RETURN message; END IF;
    SELECT assert.ok('End of test.') INTO message; RETURN message;
END $$ LANGUAGE plpgsql;


CREATE FUNCTION unit_tests.create_groups()
RETURNS test_result AS $$
DECLARE message test_result;
DECLARE result boolean;
DECLARE group_gid integer;
BEGIN
    insert into "group" (gid, name) values (27, 'sudo') RETURNING gid INTO group_gid;
    SELECT * FROM assert.is_equal(group_gid,27) INTO message, result;

    IF result = false THEN RETURN message; END IF;
    SELECT assert.ok('End of test.') INTO message; RETURN message;
END $$ LANGUAGE plpgsql;


CREATE FUNCTION unit_tests.create_users()
RETURNS test_result AS $$
DECLARE testbox integer;
DECLARE message test_result;
DECLARE result boolean;
DECLARE passwd_name text;
BEGIN
    insert into passwd (name, host, "homedir","data") values ('testuser', 'testbox.hashbang.sh', '/home/testuser', '{}'::jsonb);
    insert into passwd (name, host, "homedir","data") values ('testuser2', 'testbox.hashbang.sh', '/home/testuser2', '{}'::jsonb) returning name INTO passwd_name;
    SELECT * FROM assert.is_equal(passwd_name,'testuser2') INTO message, result;

    IF result = false THEN RETURN message; END IF;
    SELECT assert.ok('End of test.') INTO message; RETURN message;
END $$ LANGUAGE plpgsql;

CREATE FUNCTION unit_tests.add_user_to_group()
RETURNS test_result AS $$
DECLARE testbox integer;
DECLARE user_id integer;
DECLARE message test_result;
DECLARE result boolean;
DECLARE passwd_name text;
BEGIN
    insert into passwd (name, host, "homedir","data")
    values ('testadmin', 'testbox.hashbang.sh', '/home/testadmin',
    '{ "name":"Just an admin.", "shell": "/usr/bin/zsh" }'::jsonb)
    RETURNING uid INTO user_id;
    insert into aux_groups (uid, gid) values (user_id, 27); -- 27 is sudo
    SELECT "name"
    FROM passwd JOIN aux_groups
    USING (uid) WHERE (gid = 27)
    INTO passwd_name;
    SELECT * FROM assert.is_equal(passwd_name,'testadmin') INTO message, result;

    IF result = false THEN RETURN message; END IF;
    SELECT assert.ok('End of test.') INTO message; RETURN message;
END $$ LANGUAGE plpgsql;


-- Test the queries used by libnss_pgsql --

/* Return (name, passwd, gecos, dir, shell, uid, gid)
 * for a given name or uid.
 */
CREATE FUNCTION unit_tests.getpwnam()
RETURNS test_result AS $$
DECLARE message test_result;
DECLARE result     boolean;
DECLARE user_uid   integer;
DECLARE user_gid   integer;
DECLARE user_home  text;
DECLARE user_name  text;
DECLARE user_pass  text;
DECLARE user_shell text;
DECLARE user_gecos text;
BEGIN
    SELECT "name", '!', "data"->>'name', homedir, "data"->>'shell', uid, uid
      FROM passwd
     WHERE name = 'testadmin'
      INTO user_name, user_pass, user_gecos, user_home, user_shell, user_uid, user_gid;

    SELECT * FROM assert.is_equal(user_name, 'testadmin') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    SELECT * FROM assert.is_equal(user_pass, '!') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    SELECT * FROM assert.is_equal(user_gecos, 'Just an admin.') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    SELECT * FROM assert.is_equal(user_home, '/home/testadmin') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    SELECT * FROM assert.is_equal(user_shell, '/usr/bin/zsh') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    SELECT * FROM assert.is_equal(user_uid, user_gid) INTO message, result;
    IF result = false THEN RETURN message; END IF;

    -- End of test
    SELECT assert.ok('End of test.') INTO message; RETURN message;
END $$ LANGUAGE plpgsql;

CREATE FUNCTION unit_tests.getpwuid()
RETURNS test_result AS $$
DECLARE message test_result;
DECLARE result     boolean;
DECLARE user_uid   integer;
DECLARE user_gid   integer;
DECLARE user_home  text;
DECLARE user_name  text;
DECLARE user_pass  text;
DECLARE user_shell text;
DECLARE user_gecos text;
BEGIN
    -- Get uid
    SELECT uid
      FROM passwd
     WHERE "name" = 'testadmin'
      INTO user_uid;

    -- Query for getpwuid
    SELECT "name", '!', "data"->>'name', homedir, "data"->>'shell', uid, uid
      FROM passwd
     WHERE uid = user_uid
      INTO user_name, user_pass, user_gecos, user_home, user_shell, user_uid, user_gid;

    SELECT * FROM assert.is_equal(user_name, 'testadmin') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    SELECT * FROM assert.is_equal(user_pass, '!') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    SELECT * FROM assert.is_equal(user_gecos, 'Just an admin.') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    SELECT * FROM assert.is_equal(user_home, '/home/testadmin') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    SELECT * FROM assert.is_equal(user_shell, '/usr/bin/zsh') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    SELECT * FROM assert.is_equal(user_uid, user_gid) INTO message, result;
    IF result = false THEN RETURN message; END IF;

    -- End of test
    SELECT assert.ok('End of test.') INTO message; RETURN message;
END $$ LANGUAGE plpgsql;

-- TODO: test for `allusers`


/* Get (name, passwd, gid) for a given group
 * selected by id
 */
CREATE FUNCTION unit_tests.getgrgid_usergroup()
RETURNS test_result AS $$
DECLARE message test_result;
DECLARE result      boolean;
DECLARE  user_uid   integer;
DECLARE group_gid   integer;
DECLARE group_name  text;
DECLARE group_pass  text;
BEGIN
    -- Get uid
    SELECT uid
      FROM passwd
     WHERE "name" = 'testadmin'
      INTO user_uid;

    -- Query for getgrgid
    SELECT * FROM (
      SELECT name, '!', gid
      FROM "group"
      WHERE gid  = user_uid
    UNION
      SELECT name, '!', uid
      FROM passwd
      WHERE uid  = user_uid
    ) AS temp INTO group_name, group_pass, group_gid;

    SELECT * FROM assert.is_equal(group_name, 'testadmin') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    SELECT * FROM assert.is_equal(group_pass, '!') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    SELECT * FROM assert.is_equal(group_gid, user_uid) INTO message, result;
    IF result = false THEN RETURN message; END IF;

    -- End of test
    SELECT assert.ok('End of test.') INTO message; RETURN message;
END $$ LANGUAGE plpgsql;

CREATE FUNCTION unit_tests.getgrgid_systemgroup()
RETURNS test_result AS $$
DECLARE message test_result;
DECLARE result      boolean;
DECLARE group_gid   integer;
DECLARE group_name  text;
DECLARE group_pass  text;
BEGIN
    -- Get uid
    SELECT gid
      FROM "group"
     WHERE "name" = 'sudo'
      INTO group_gid;

    -- Query for getgrgid
    SELECT * FROM (
      SELECT name, '!', gid
      FROM "group"
      WHERE gid  = group_gid
    UNION
      SELECT name, '!', uid
      FROM passwd
      WHERE uid  = group_gid
    ) AS temp INTO group_name, group_pass, group_gid;

    SELECT * FROM assert.is_equal(group_name, 'sudo') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    SELECT * FROM assert.is_equal(group_pass, '!') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    SELECT * FROM assert.is_equal(group_gid, 27) INTO message, result;
    IF result = false THEN RETURN message; END IF;

    -- End of test
    SELECT assert.ok('End of test.') INTO message; RETURN message;
END $$ LANGUAGE plpgsql;


/* Get (name, passwd, gid) for a given group
 * selected by name
 */
CREATE FUNCTION unit_tests.getgrnam_usergroup()
RETURNS test_result AS $$
DECLARE message test_result;
DECLARE result      boolean;
DECLARE  user_uid   integer;
DECLARE group_gid   integer;
DECLARE group_name  text;
DECLARE group_pass  text;
BEGIN
    -- Get uid
    SELECT uid
      FROM passwd
     WHERE "name" = 'testadmin'
      INTO user_uid;

    -- Query for getgrnam
    SELECT * FROM (
      SELECT name, '!', gid
      FROM "group"
      WHERE name = 'testadmin'
    UNION
      SELECT name, '!', uid
      FROM passwd
      WHERE name = 'testadmin'
    ) AS temp INTO group_name, group_pass, group_gid;

    SELECT * FROM assert.is_equal(group_name, 'testadmin') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    SELECT * FROM assert.is_equal(group_pass, '!') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    SELECT * FROM assert.is_equal(group_gid, user_uid) INTO message, result;
    IF result = false THEN RETURN message; END IF;

    -- End of test
    SELECT assert.ok('End of test.') INTO message; RETURN message;
END $$ LANGUAGE plpgsql;

CREATE FUNCTION unit_tests.getgrnam_systemgroup()
RETURNS test_result AS $$
DECLARE message test_result;
DECLARE result      boolean;
DECLARE group_gid   integer;
DECLARE group_name  text;
DECLARE group_pass  text;
BEGIN
    -- Query for getgrnam
    SELECT * FROM (
      SELECT name, '!', gid
      FROM "group"
      WHERE name = 'sudo'
    UNION
      SELECT name, '!', uid
      FROM passwd
      WHERE name = 'sudo'
    ) AS temp INTO group_name, group_pass, group_gid;

    SELECT * FROM assert.is_equal(group_name, 'sudo') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    SELECT * FROM assert.is_equal(group_pass, '!') INTO message, result;
    IF result = false THEN RETURN message; END IF;

    SELECT * FROM assert.is_equal(group_gid, 27) INTO message, result;
    IF result = false THEN RETURN message; END IF;

    -- End of test
    SELECT assert.ok('End of test.') INTO message; RETURN message;
END $$ LANGUAGE plpgsql;

-- TODO: Add user/group tests (groups_dyn & getgroupmembersbygid)


-- Query used by Postfix
CREATE FUNCTION unit_tests.postfix()
RETURNS test_result AS $$
DECLARE message test_result;
DECLARE result boolean;
DECLARE passwd_host text;
BEGIN
    SELECT host FROM passwd WHERE name = 'testuser' INTO passwd_host;
    SELECT * FROM assert.is_equal(passwd_host, 'testbox.hashbang.sh') INTO message, result;

    IF result = false THEN RETURN message; END IF;
    SELECT assert.ok('End of test.') INTO message; RETURN message;
END $$ LANGUAGE plpgsql;


-- End of file: run all tests
SELECT * FROM unit_tests.begin();
