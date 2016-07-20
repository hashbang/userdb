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
        "location": "Undisclosed location",
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

SELECT * FROM unit_tests.begin();
