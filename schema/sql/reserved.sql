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
      and not exists(select 1 from reserved_usernames
	             where reserved_usernames.name = tmp_table.name);
      truncate tmp_table;
    end$$;

-- reserve names in ldpreload.com, RFC2142, and common conventions
insert into tmp_table (name) values
    ('abuse'),
    ('admin'),
    ('administrator'),
    ('autoconfig'),
    ('broadcasthost'),
    ('ftp'),
    ('hostmaster'),
    ('imap'),
    ('info'),
    ('is'),
    ('isatap'),
    ('it'),
    ('localdomain'),
    ('localhost'),
    ('mail'),
    ('mailer-daemon'),
    ('marketing'),
    ('mis'),
    ('news'),
    ('nobody'),
    ('noc'),
    ('noreply'),
    ('pop'),
    ('pop3'),
    ('postmaster'),
    ('root'),
    ('sales'),
    ('security'),
    ('smtp'),
    ('ssladmin'),
    ('ssladministrator'),
    ('sslwebmaster'),
    ('support'),
    ('sysadmin'),
    ('team'),
    ('usenet'),
    ('uucp'),
    ('webmaster'),
    ('wpad'),
    ('www');

select pg_temp.import_reserved();
