-- -*- mode: sql; sql-product: postgres -*-

create user "api" noinherit;
comment on role api is
    $$API role used for API abstractions like PostgREST$$;
alter role "api" with login;
alter view v1."hosts" owner to api;
alter view v1."passwd" owner to api;
alter view v1."group" owner to api;
alter view v1."aux_groups" owner to api;
grant usage on schema public to api;
grant create,usage on schema v1 to api;
grant select,insert,update,delete on table
    public."reserved_usernames",
    public."hosts",
    public."passwd",
    public."aux_groups",
    public."group"
to "api";

create role "api-anon";
comment on role "api-anon" is
    $$Internal api-anonymous read access for API$$;
grant usage on schema v1 to "api-anon";
grant usage on sequence user_id to "api-anon";
grant select on table
    public."reserved_usernames",
    v1."aux_groups",
    v1."group",
    v1."hosts",
    v1."passwd"
to "api-anon";
grant "api-anon" to "api";

create role "api-user-create";
comment on role "api-user-create" is
    $$Intended for use with user creation systems$$;
grant usage on sequence "user_id" to "api-user-create";
grant select on table public."hosts" to "api-user-create";
grant insert on table public."group",public."passwd" to "api-user-create";
grant "api-user-create" to "api";

create user "ssh_auth" inherit;
comment on role "ssh_auth" is
    $$Access for ssh via AuthorizedKeysCommand$$;
alter role "ssh_auth" with login;
grant select on table
    public."group",
    public."passwd",
    public."aux_groups"
to "ssh_auth";

create user "mail" inherit;
comment on role "mail" is
    $$Access for MTAs like Postfix$$;
alter role "mail" with login;

create user "nss_pgsql";
comment on role "nss_pgsql" is
    $$Intended for nss-pgsql NSS module$$;
alter role "nss_pgsql" with login;
grant select on
    public."passwd",
    public."aux_groups",
    public."group",
    nss_pgsql."passwd",
    nss_pgsql."group",
    nss_pgsql."groupmember",
    nss_pgsql."groups_dyn",
    nss_pgsql."shadow"
to "nss_pgsql";
