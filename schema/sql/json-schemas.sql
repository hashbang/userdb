-- -*- mode: sql; sql-product: postgres -*-

-- JSON schema for user data
alter table passwd add constraint data_user
check(validate_json_schema($${data_user}$$::jsonb, data));

-- JSON schema for host data
alter table hosts add constraint data_host
check(validate_json_schema($${data_host}$$::jsonb, data));
