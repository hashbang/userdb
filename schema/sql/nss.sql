-- -*- mode: sql; sql-product: postgres -*-

create user "nss_pgsql";
comment on role "nss_pgsql" is
    $$Intended for nss-pgsql NSS module$$;
alter role "nss_pgsql" with login;
grant select on
    public."passwd",
    public."aux_groups",
    public."group"
to "nss_pgsql";

create schema nss_pgsql;

create view nss_pgsql.groupmember as
    select
        name as username,
        uid as gid
    from public.passwd
    union
    select
        name as usernames,
        aux_groups.gid as gid
        from public.passwd inner join public.aux_groups
            on (passwd.uid = aux_groups.uid);

create view nss_pgsql.passwd as
    select
        name,
        'x' as "passwd",
        data->>'name' as "gecos",
        '/home/' || name as "dir",
        data->>'shell' as "shell",
        uid,
        uid as gid
    from public.passwd;
grant select on nss_pgsql.passwd to nss_pgsql;

create view nss_pgsql."group" as
    select
        passwd.name,
        'x' as passwd,
        passwd.uid as gid,
        ARRAY[passwd.name] as members
    from public.passwd
    union
    select
        name,
        'x' as passwd,
        gid,
        ARRAY(
            select passwd.name
            from public.passwd inner join public.aux_groups
                on (passwd.uid = aux_groups.uid and aux_groups.gid = "group".gid)
        ) as members
    from public."group";
grant select on nss_pgsql."group" to nss_pgsql;

create view nss_pgsql.groups_dyn as
    select
        name,
        gid
    from public.aux_groups inner join public.passwd
        on (aux_groups.uid = passwd.uid);
grant select on nss_pgsql.groups_dyn to nss_pgsql;

create view nss_pgsql.shadow as
    select
        name,
        '!' as passwd,
        18086 as lstchg,
        0 as min,
        99999 as max,
        0 as warn,
        99999 as inact,
        0 as expire,
        0 as flag
    from public.passwd;
grant select on nss_pgsql.shadow to nss_pgsql;
