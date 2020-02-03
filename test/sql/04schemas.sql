-- -*- mode: sql; sql-product: postgres -*-

-- Negative tests for the JSON schemas:
-- check invalid data cannot be inserted

CREATE FUNCTION unit_tests.json_hosts()
RETURNS test_result AS $$
BEGIN
    BEGIN
        insert into hosts (name, data) values ('invalid.hashbang.sh', '{}'::jsonb);
    	RETURN assert.fail('Successfully inserted user.');
    EXCEPTION
	WHEN check_violation THEN
	    RETURN assert.ok('End of test.');
    END;
END $$ LANGUAGE plpgsql;

CREATE FUNCTION unit_tests.json_passwd()
RETURNS test_result AS $$
DECLARE message test_result;
BEGIN
    BEGIN
        insert into passwd (name, host, shell)
        values ('invaliduser', 'testbox.hashbang.sh', '/bin/bash');
    	RETURN assert.fail('Successfully inserted user.');
    EXCEPTION
	WHEN check_violation THEN
	    RETURN assert.ok('End of test.');
    END;
END $$ LANGUAGE plpgsql;
