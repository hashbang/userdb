CREATE FUNCTION unit_tests.create_hosts()
RETURNS test_result AS $$
DECLARE message test_result;
DECLARE result boolean;
DECLARE host_name text;
BEGIN
    insert into hosts (name, ips) values ('testbox', ARRAY['192.13.3.134'::inet]) returning name INTO host_name;
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
    insert into "group" (name) values ('testuser1');
    insert into "group" (name) values ('testuser2') returning gid INTO group_gid;
    SELECT * FROM assert.is_equal(group_gid,4001) INTO message, result;

    IF result = false THEN RETURN message; END IF;
    SELECT assert.ok('End of test.') INTO message; RETURN message; 
END $$ LANGUAGE plpgsql;


CREATE FUNCTION unit_tests.create_users()
RETURNS test_result AS $$
DECLARE message test_result;
DECLARE result boolean;
DECLARE passwd_name text;
BEGIN
    insert into passwd (name, gid, host, "homeDir","sshKeys") values ('testuser', 4002, 1, '/home/testuser', ARRAY[]::text[]);
    insert into passwd (name, gid, host, "homeDir","sshKeys") values ('testuser2', 4003, 1, '/home/testuser2', ARRAY[]::text[]) returning name INTO passwd_name;
    SELECT * FROM assert.is_equal(passwd_name,'testuser2') INTO message, result;

    IF result = false THEN RETURN message; END IF;
    SELECT assert.ok('End of test.') INTO message; RETURN message; 
END $$ LANGUAGE plpgsql;


SELECT * FROM unit_tests.begin();
