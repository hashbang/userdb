-- -*- mode: sql; sql-product: postgres -*-

create user "postgres" inherit;
create role "postgres";
comment on role postgres is "Administrator access"
alter role "postgres" with
    login,
    superuser,
    createrole,
    createdb,
    replication,
    bypassrls;

create user "anon" inherit;
create role "anon";
comment on role "anon" is "For anonymous read access by the public"
alter role "anon" with nologin;
grant usage on schema v1 to "anon";
grant usage on sequence user_id to "anon";
grant select on table
    public."reserved_usernames",
    v1."aux_groups",
    v1."group",
    v1."hosts",
    v1."passwd",
to "anon";

create user "api" noinherit;
create role "api";
comment on role api is "API role used for API abstractions like PostgREST"
alter role "api" with login;
alter view v1."hosts" owner to api;
alter view v1."passwd" owner to api;
alter view v1."group" owner to api;
alter view v1."aux_groups" owner to api;
grant "anon" to api;
grant usage on schema public to api;
grant create,usage on schema v1 to api;
grant select,insert,update,delete on table
    public."reserved_usernames",
    public."hosts",
    public."passwd",
    public."aux_groups",
    public."group",
to "api";

create user "ssh_auth" inherit;
create role "ssh_auth";
comment on role "ssh_auth" is "Access for ssh via AuthorizedKeysCommand"
alter role "ssh_auth" with login;
grant select on table
    public."group",
    public."passwd",
    public."aux_groups"
to "ssh_auth";

create user "mail" inherit;
create role "mail";
comment on role "mail" is "Access for MTAs like Postfix"
alter role "mail" with login;

create user "create_users";
create role "create_users";
comment on role "create_users" is "Intended for use with user creation systems"
alter role "create_users" with nologin;
grant usage on sequence "user_id" to "create_users";
grant select on table public."hosts" to "create_users";
grant insert on table public."group",public."passwd" to "create_users";

create user "nss_pgsql";
create role "nss_pgsql";
comment on role "nss_pgsql" is "Intended for nss-pgsql NSS module"
grant select on
    public."passwd",
    public."aux_groups",
    public."group",
    nss_pgsql."passwd",
    nss_pgsql."group",
    nss_pgsql."groupmember"
    nss_pgsql."groups_dyn",
    nss_pgsql."shadow"
to "nss_pgsql";
