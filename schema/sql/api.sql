-- -*- mode: sql; sql-product: postgres -*-
create schema pgcrypto;
create extension if not exists pgcrypto schema pgcrypto;

create user "api" noinherit;
comment on role api is
    $$API role used for API abstractions like PostgREST$$;
alter role "api" with login;
grant usage on schema public to api;
grant select,insert,update,delete on table
    public."reserved_usernames",
    public."hosts",
    public."passwd",
    public."aux_groups",
    public."group",
    public."ssh_public_key",
    public."openpgp_public_key"
to "api";

create role "api-anon";
comment on role "api-anon" is
    $$Internal api-anonymous read access for API$$;
grant usage on sequence user_id to "api-anon";
grant "api-anon" to "api";
grant select on table public."reserved_usernames" to "api-anon";

create role "api-user-create";
comment on role "api-user-create" is
    $$Intended for use with user creation systems$$;
grant usage on sequence "user_id" to "api-user-create";
grant "api-user-create" to "api";
grant "api-anon" to "api-user-create";

create role "api-user-manage";
comment on role "api-user-manage" is
    $$Intended for use with user management systems$$;
grant usage on sequence "user_id" to "api-user-manage";
grant "api-user-manage" to "api";
grant "api-anon" to "api-user-manage";

create schema v1;
grant create,usage on schema v1 to api;
grant usage on schema v1 to "api-anon";
grant usage on schema v1 to "api-user-manage";

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
alter view v1."hosts" owner to api;
grant select on table v1."hosts" to "api-anon";

create view v1.passwd as
    select
        uid,
        name,
        host,
        shell,
        data
    from public.passwd;
comment on view v1.passwd is
    $$Users$$;
comment on column v1.passwd.uid is
    $$User's unique ID$$;
comment on column v1.passwd.host is
    $$User's 'home' host$$;
comment on column v1.passwd.shell is
    $$User's configured shell$$;
comment on column v1.passwd.data is
    $$Extra user data$$;
alter view v1."passwd" owner to api;
grant select on table v1."passwd" to "api-anon";
grant insert("name","host","data") on table v1."passwd" to "api-user-create";
grant insert("name","host","data") on table v1."passwd" to "api-user-manage";
grant update("host","data") on table v1."passwd" to "api-user-manage";

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
alter view v1."group" owner to api;
grant select on table v1."group" to "api-anon";

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
alter view v1."aux_groups" owner to api;
grant select on table v1."aux_groups" to "api-anon";

create view v1.ssh_public_key as
    select
        encode(fingerprint, 'hex') as fingerprint,
        encode(fingerprint, 'base64') as base64_fingerprint,
        type,
        key,
        comment,
        uid
    from public.ssh_public_key;
comment on view v1.ssh_public_key is
    $$SSH public keys for users$$;
comment on column v1.ssh_public_key.fingerprint is
    $$Hex fingerprint for public key$$;
comment on column v1.ssh_public_key.base64_fingerprint is
    $$Base64 fingerprint for public key$$;
comment on column v1.ssh_public_key.type is
    $$Type of SSH key (dsa/rsa/ecdsa/ed25519/u2f)$$;
comment on column v1.ssh_public_key.key is
    $$Public key formatted as OpenSSH public key format$$;
comment on column v1.ssh_public_key.comment is
    $$Comment from the third field of the OpenSSH public key format$$;
comment on column v1.ssh_public_key.uid is
    $$User ID the key is currently linked to$$;
alter view v1."ssh_public_key" owner to api;
grant select on table v1."ssh_public_key" to "api-anon";
grant update,delete,insert on table v1."ssh_public_key" to "api-user-manage";

-- PGP Key
create view v1.openpgp_public_key as
  select
      uid,
      pgcrypto.dearmor(ascii_armoured_public_key) as key,
      ascii_armoured_public_key
  from public.openpgp_public_key;
comment on view v1.openpgp_public_key is
    $$PGP public keys for users$$;
comment on column v1.openpgp_public_key.key is
    $$PGP public key$$;
comment on column v1.openpgp_public_key.ascii_armoured_public_key is
    $$ASCII armoured PGP key$$;
comment on column v1.openpgp_public_key.uid is
    $$User ID the key is currently linked to$$;
grant insert("uid", "ascii_armoured_public_key") on table v1."openpgp_public_key" to "api-user-create";
grant update("uid", "ascii_armoured_public_key") on table v1."openpgp_public_key" to "api-user-manage";

create function insert_pgp_key() returns trigger as $$
begin
  insert into public.openpgp_public_key (uid, ascii_armoured_public_key)
    values (new.uid, new.ascii_armoured_public_key);
  return new;
end
$$ language plpgsql security definer;

create trigger insert_pgp_key
    instead of insert on v1.openpgp_public_key
    for each row
    execute procedure insert_pgp_key();

alter view v1."openpgp_public_key" owner to api;
grant select on table v1."openpgp_public_key" to "api-anon";


-- User signup
create view v1.signup as
    select
        p.name as name,
        p.host as host,
        p.uid as uid,
        array_agg(keys.type || ' ' || keys.key) as keys,
        p.shell as shell
    from
        public.passwd p
        left join public.ssh_public_key keys on p.uid = keys.uid
    group by p.name, p.host, p.uid, p.shell;
comment on view v1.signup is
    $$Route for POSTable signup$$;
comment on column v1.signup.name is
    $$Username$$;
comment on column v1.signup.host is
    $$User's default home system$$;
comment on column v1.signup.keys is
    $$User's raw SSH keys$$;
comment on column v1.signup.shell is
    $$User's default shell$$;

create function signup() returns trigger as $$
declare
    new_user_id int;
    temp_key_type text;
    temp_key_value text;
    temp_key_comment text;
    key text;
begin
    insert into public.passwd (name, host, shell)
        values (new.name, new.host, new.shell)
        returning uid into new_user_id;
    for key in select * from unnest(new.keys)
    loop
        temp_key_type = split_part(key, ' ', 1);
        temp_key_value = split_part(key, ' ', 2);
        temp_key_comment = split_part(key, ' ', 3);
        insert into public.ssh_public_key (type, key, comment, uid)
            values (temp_key_type::ssh_key_type, temp_key_value, temp_key_comment, new_user_id);
    end loop;
    return new;
end
$$ language plpgsql security definer;

create trigger signup
    instead of insert on v1.signup
    for each row
    execute procedure signup();

alter view v1."signup" owner to api;
grant select on table v1."signup" to "api-anon";
grant insert("name", "host", "shell", "keys") on table v1."signup" to "api-user-create";
grant insert("name", "host", "shell", "keys") on table v1."signup" to "api-user-manage";
