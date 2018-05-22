-- -*- mode: sql; sql-product: postgres -*-

-- hosts table
create domain hostname_t text check (
  value ~ '^([a-z0-9]+\.)+hashbang\.sh$'
);

create table "hosts" (
  "name" hostname_t primary key,
  "maxusers" integer check(maxusers >= 0),
  "data" jsonb -- extra data added in the stats answer
               -- conforms to the host_data.yaml schema
);

-- data for NSS' passwd
-- there is an implicit primary group for each user
-- UID and GID ranges conform to Debian policy:
--  https://www.debian.org/doc/debian-policy/ch-opersys.html#s9.2.2
create sequence user_id minvalue 4000 maxvalue 59999 no cycle;

create domain username_t text check (
  value ~ '^[a-z][a-z0-9]{0,30}$'
);

create table "passwd" (
  "uid" integer primary key
    check((uid >= 1000 and uid < 60000) or (uid > 65535 and uid < 4294967294))
    default nextval('user_id'),
  "name" username_t unique not null,
  "host" text not null references hosts (name),
  "data" jsonb  -- conforms to the user_data.yaml schema
    check(length(data::text) < 1048576) -- max 1M
);

alter sequence user_id owned by passwd.uid;

-- auxiliary groups
create table "group" (
  "gid" integer primary key check(gid < 1000 or (gid >= 60000 and gid < 65000)),
  "name" username_t unique not null
);

create table "aux_groups" (
  "uid" int4 not null references passwd  (uid) on delete cascade,
  "gid" int4 not null references "group" (gid) on delete cascade,
  primary key ("uid", "gid")
);

-- prevent creation/update of a user/host if the number of users
-- in the group 'users' that have that host
-- is equal to the maxUsers for that host
create function check_hosts_for_hosts() returns trigger
    language plpgsql as $$
    begin
        if ((select count(*) from passwd where passwd.host = new.name) <= new.maxusers) then
            raise foreign_key_violation using message = 'current maxUsers too high for host: '||new.name;
        end if;
        return new;
    end $$;
create constraint trigger max_users_on_host
    after update on hosts
    for each row
    when (old.maxusers <> new.maxusers)
    execute procedure check_hosts_for_hosts();

-- prevent creation/update of a user if the number of users
-- associated to that host is equal to maxUsers
create function check_max_users() returns trigger
    language plpgsql as $$
    begin
	if (tg_op = 'INSERT' or old.host <> new.host) and
	   (select count(*) from passwd where passwd.host = new.host) >= (select "maxusers" from hosts where hosts.name = new.host) then
	    raise foreign_key_violation using message = 'maxUsers reached for host: '||new.host;
	end if;
	return new;
    end $$;
create constraint trigger max_users
    after insert or update on passwd
    for each row execute procedure check_max_users();

-- prevent users and groups sharing the same name
create function check_invalid_name_for_passwd() returns trigger
    language plpgsql as $$
    begin
        if (exists(select 1 from "group" where new.name = name)) then
            raise check_violation using message = 'group name already exists: '||new.name;
        end if;
	return new;
    end $$;
create constraint trigger check_name_exists_passwd
    after insert or update on passwd
    for each row
    execute procedure check_invalid_name_for_passwd();

create function check_invalid_name_for_group() returns trigger
    language plpgsql as $$
    begin
        if (exists(select 1 from passwd where new.name = name)) then
            raise check_violation using message = 'username already exists: '||new.name;
        end if;
	return new;
    end $$;
create constraint trigger check_name_exists_group
    after insert or update on "group"
    for each row
    execute procedure check_invalid_name_for_group();

-- create role for creating new users
-- grant only rights to add new users
create role "create_users";
grant insert on table "group",passwd to "create_users";
grant select on table "hosts" to "create_users";
grant usage on sequence user_id to "create_users";
