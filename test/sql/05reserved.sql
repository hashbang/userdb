-- -*- mode: sql; sql-product: postgres -*-

-- Negative test for `reserved_usernames`:
-- check that reserved names cannot be inserted.
create function unit_tests.reserved_usernames()
returns test_result as $$
declare message test_result;
begin
    begin
        insert into passwd (name, host, shell)
        values ('noc', 'fo0.hashbang.sh','/bin/zsh' );
        return assert.fail('Successfully inserted invalid user.');
    exception
    when check_violation then
        return assert.ok('End of test.');
    end;
end $$ language plpgsql;
