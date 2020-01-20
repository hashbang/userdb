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
    ('mailer-daemon'),
    ('nobody'),
    ('root'),
    ('team'),
    ('info'),
    ('marketing'),
    ('sales'),
    ('support'),
    ('abuse'),
    ('noc'),
    ('security'),
    ('postmaster'),
    ('hostmaster'),
    ('usenet'),
    ('news'),
    ('webmaster'),
    ('www'),
    ('uucp'),
    ('ftp'),
    ('admin'),
    ('administrator'),
    ('autoconfig'),
    ('broadcasthost'),
    ('imap'),
    ('is'),
    ('isatap'),
    ('it'),
    ('localdomain'),
    ('localhost'),
    ('mail'),
    ('mis'),
    ('noreply'),
    ('pop'),
    ('pop3'),
    ('smtp'),
    ('ssladmin'),
    ('ssladministrator'),
    ('sslwebmaster'),
    ('sysadmin'),
    ('wpad');

select pg_temp.import_reserved();
