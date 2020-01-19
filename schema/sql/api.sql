-- -*- mode: sql; sql-product: postgres -*-

--- Set up roles

create user api noinherit
    password 'API_PASSWORD'; -- Hardcoded. Change after deployment
comment on role api is
$$The api user is used to pivot into other roles.

It should have no permissions itself$$;
grant usage on schema public to api; -- allow api role to use types from core

create schema v1 authorization current_user;
grant api to current_user; -- allow current_user to hand over things to api role
grant create,usage on schema v1 to api; -- allow api role to own views in schema

create role anon;
comment on role anon is
$$The anon role should only be able to see/do what we expect an anonymous member of the public to be able to do$$;
grant anon to api;
grant usage on schema v1 to anon;

--- Set up public API

create view v1.hosts as
    select
        name,
        maxusers,
        data,
    from public.hosts;
comment on view v1.hosts is
    $$Contains the hashbang servers$$;
comment on column v1.hosts.name is
    $$Host's domain name$$;
comment on column v1.hosts.maxusers is
    $$The maximum users supported by this server$$;
comment on column v1.hosts.data is
    $$Extra data added in the stats answer.$$;
grant select on table v1.hosts to anon;
alter view v1.hosts owner to api;
grant select,insert,update,delete on table public.hosts to api;


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
grant select on table v1.passwd to anon;
alter view v1.passwd owner to api;
grant select,insert,update,delete on table public.passwd to api;

grant usage on sequence user_id to anon;

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
grant select on table v1."group" to anon;
alter view v1."group" owner to api;
grant select,insert,update,delete on table public."group" to api;


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
grant select on table v1.aux_groups to anon;
alter view v1.aux_groups owner to api;
grant select,insert,update,delete on table public.aux_groups to api;


grant select,insert,update,delete on table public.reserved_usernames to api;


--- Finish up
revoke api from current_user;
