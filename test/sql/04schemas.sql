-- -*- mode: sql; sql-product: postgres -*-

-- Negative tests for the JSON schemas:
-- check invalid data cannot be inserted

-- Fails because of invalid required JSON data.
CREATE FUNCTION unit_tests.json_hosts()
RETURNS test_result AS $$
BEGIN
    BEGIN
        insert into hosts (name, data) values ('invalid.hashbang.sh', '{}'::jsonb);
        RETURN assert.fail('Successfully inserted invalid host');
    EXCEPTION
	WHEN check_violation THEN
	    RETURN assert.ok('End of test.');
    END;
END $$ LANGUAGE plpgsql;

-- Users now have no required JSON data.
