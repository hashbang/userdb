-- -*- mode: sql; sql-product: postgres -*-

-- JSON schema for user data
ALTER TABLE passwd ADD CONSTRAINT data_user
CHECK(validate_json_schema($${data_user}$$::jsonb, data));

-- JSON schema for host data
ALTER TABLE hosts ADD CONSTRAINT data_host
CHECK(validate_json_schema($${data_host}$$::jsonb, data));

