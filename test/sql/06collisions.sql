-- Negative tests for `check_hosts_for_hosts`, `check_invalid_name_for_passwd`,
-- `check_invalid_name_for_group`, `check_reserved_username`, and
-- `check_taken_username`

create function unit_tests.check_hosts_for_hosts()
returns test_result as $$
begin
    insert into hosts (name, maxusers) values ('06invalid.hashbang.sh', 1);
    insert into passwd (name, host) values ('ryan', '06invalid.hashbang.sh');
    begin
        update hosts set maxusers = 0 where name = '06invalid.hashbang.sh';
        return assert.fail('Successfully changed maxusers to be less than users');
    exception
    when foreign_key_violation then
        return assert.ok('End of test.');
    end;
end $$ language plpgsql;

create function unit_tests.check_invalid_name_for_passwd()
returns test_result as $$
begin
    insert into hosts (name, maxusers) values ('061invalid.hashbang.sh', 1);
    insert into "group" (gid, name) values (600, 'grouptest06');
    begin
        insert into passwd (name, host) values ('grouptest06', '061invalid.hashbang.sh');
        return assert.fail('Successfully added group name collision from user');
    exception
    when check_violation then
        return assert.ok('End of test.');
    end;
end $$ language plpgsql;

create function unit_tests.check_invalid_name_for_group()
returns test_result as $$
begin
    insert into hosts (name, maxusers) values ('062invalid.hashbang.sh', 1);
    insert into passwd (name, host) values ('passwdtest06', '062invalid.hashbang.sh');
    begin
        insert into "group" (gid, name) values (601, 'passwdtest06');
        return assert.fail('Successfully added passwd name collision from group');
    exception
    when check_violation then
        return assert.ok('End of test.');
    end;
end $$ language plpgsql;

create function unit_tests.check_reserved_username()
returns test_result as $$
begin
    insert into reserved_usernames (name) values ('user063');
    insert into hosts (name, maxusers) values ('063invalid.hashbang.sh', 1);
    begin
        insert into passwd (name, host) values ('user063', '063invalid.hashbang.sh');
        return assert.fail('Successfully registered reserved name');
    exception
    when check_violation then
        return assert.ok('End of test.');
    end;
end $$ language plpgsql;

create function unit_tests.check_taken_username()
returns test_result as $$
begin
    insert into hosts (name, maxusers) values ('064invalid.hashbang.sh', 1);
    insert into passwd (name, host) values ('user064', '064invalid.hashbang.sh');
    begin
        insert into reserved_usernames (name) values ('user064');
        return assert.fail('Successfully reserved a registered name');
    exception
    when check_violation then
        return assert.ok('End of test.');
    end;
end $$ language plpgsql;
