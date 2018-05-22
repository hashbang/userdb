-- -*- mode: sql; sql-product: postgres -*-
-- An helper for bulk-importing the data
create temp table tmp_table (
"name" text unique not null
);
create function pg_temp.import_reserved() returns void
    language plpgsql as $$
    begin
      insert into reserved_usernames
      select *
      from tmp_table
      where name ~ '^[a-z][a-z0-9]{0,30}$'
      on conflict do nothing;
      truncate tmp_table;
    end$$;

-- Aliases in our mail server configuration:
--  https://github.com/hashbang/admin-tools/blob/master/files/postfix/aliases.j2
--
-- This does not include common aliases defined by RFC 2142
\copy tmp_table (name) from './reserved/aliases';
select pg_temp.import_reserved();

-- List of reserved usernames by Geoffrey Thomas:
--   https://ldpreload.com/blog/names-to-reserve
\copy tmp_table (name) from './reserved/ldpreload.com';
select pg_temp.import_reserved();

-- Email aliases reserved by RFC 2142:
--  https://www.ietf.org/rfc/rfc2142.txt
\copy tmp_table (name) from './reserved/rfc2142';
select pg_temp.import_reserved();
