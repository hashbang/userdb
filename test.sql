-- Basic operations populating the database.

CREATE FUNCTION unit_tests.create_hosts()
RETURNS test_result AS $$
DECLARE message test_result;
DECLARE result boolean;
DECLARE host_name text;
BEGIN
    insert into hosts (name, data) values ('testbox', '{
	"inet": ["192.0.2.4"],
	"coordinates": {
	    "lat": 0,
	    "lon": 0
	},
	"location": "Undisclosed location",
	"maxUsers": 1000
     }'::jsonb) returning name INTO host_name;
    SELECT * FROM assert.is_equal(host_name,'testbox') INTO message, result;

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
--    SELECT id FROM hosts WHERE "name" = "testbox" INTO testbox;
    insert into passwd (name, host, "homedir","data") values ('testuser', 1, '/home/testuser', '{}'::jsonb);
    insert into passwd (name, host, "homedir","data") values ('testuser2', 1, '/home/testuser2', '{}'::jsonb) returning name INTO passwd_name;
    SELECT * FROM assert.is_equal(passwd_name,'testuser2') INTO message, result;

    IF result = false THEN RETURN message; END IF;
    SELECT assert.ok('End of test.') INTO message; RETURN message;
END $$ LANGUAGE plpgsql;


-- End of file: run all tests
SELECT * FROM unit_tests.begin();
