-- -*- mode: sql; sql-product: postgres -*-

create schema v1;

create view v1.hosts as
    select
        hosts.name,
        hosts.maxusers,
        hosts.data
    from public.hosts;
comment on view v1.hosts is
    $$Contains the hashbang servers$$;
comment on column v1.hosts.name is
    $$Host's domain name$$;
comment on column v1.hosts.maxusers is
    $$The maximum users supported by this server$$;
comment on column v1.hosts.data is
    $$Extra data added in the stats answer.$$;

create view v1.passwd as
    select
        uid,
        name,
        host,
        data
    from public.passwd;
comment on view v1.passwd is
    $$Users$$;
comment on column v1.passwd.uid is
    $$User's unique ID$$;
comment on column v1.passwd.host is
    $$User's 'home' host$$;
comment on column v1.passwd.data is
    $$Extra user data$$;

create view v1."group" as
    select
        gid,
        name
    from public."group";
comment on view v1."group" is
    $$Groups$$;
comment on column v1."group".gid is
    $$Group ID$$;
comment on column v1."group".name is
    $$Group Name$$;

create view v1.aux_groups as
    select
        uid,
        gid
    from public.aux_groups;
comment on view v1.aux_groups is
    $$User<>Group relationships$$;
comment on column v1.aux_groups.uid is
    $$User ID$$;
comment on column v1.aux_groups.gid is
    $$Group ID$$;

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
grant insert("name","host","data") on table v1."passwd" to "api-user-create";
grant "api-user-create" to "api";
grant "api-anon" to "api-user-create";
