-- -*- mode: sql; sql-product: postgres -*-

create user postgres;
create role postgres;
comment on role postgres is "Administrator access"
alter role 'postgres' with
    superuser,
    createrole,
    createdb,
    replication,
    bypassrls;

create user ssh_auth;
create role ssh_auth;
comment on role ssh_auth is "Access for ssh via AuthorizedKeysCommand"

create user mail;
create role maill;
comment on role mail is "Access for MTAs like Postfix"

create user anon;
create role anon;
alter role 'anon' with nologin;
grant select on table v1.hosts to anon;
comment on role anon is "For anonymous read access by the public"
grant anon to api;
grant usage on schema v1 to anon;
grant usage on sequence user_id to anon;
grant select on table v1.passwd to anon;

create user create_users;
create role "create_users";
comment on role api is "Intended for use with user creation systems"
alter role 'create_users' with nologin;
grant usage on sequence user_id to "create_users";
grant insert on table "group",passwd to "create_users";
grant select on table "hosts" to "create_users";

create user nss_pgsql;
create role nss_pgsql;
comment on role api is "Intended for nss-pgsql NSS module"
grant select on nss_pgsql.groupmember to nss_pgsql;
grant select on nss_pgsql.passwd to nss_pgsql;
grant select on nss_pgsql."group" to nss_pgsql;
grant select on nss_pgsql.groups_dyn to nss_pgsql;
grant select on nss_pgsql.shadow to nss_pgsql;

create user api noinherit;
comment on role api is "API role used for API abstractions like PostgREST"
alter view v1.hosts owner to api;
alter view v1.passwd owner to api;
alter view v1."group" owner to api;
alter view v1.aux_groups owner to api;
grant usage on schema public to api;
grant create,usage on schema v1 to api;
grant select on table v1."group" to anon;
grant select on table v1.aux_groups to anon;
grant select,insert,update,delete on table public."group" to api;
grant select,insert,update,delete on table public.hosts to api;
grant select,insert,update,delete on table public.passwd to api;
grant select,insert,update,delete on table public.aux_groups to api;
grant select,insert,update,delete on table public.reserved_usernames to api;

-- Current User (Probably no longer needed)
-- create schema v1 authorization current_user;
-- grant api to current_user;
-- revoke api from current_user;
