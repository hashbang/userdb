-- -*- mode: sql; product: postgres -*-

create extension if not exists postgis;

-- hosts table
create table "hosts" (
  "id" serial primary key,
  "name" text unique not null,
  "location" text,
  -- 4326 is the EPSG standard for lat/lon
  "coordinates" geography (point, 4326),
  "maxUsers" integer check ("maxUsers" >= 0),
  "ips" inet[] not null
);

-- data for NSS' passwd
-- there is an implicit primary group for each user
create sequence user_id minvalue 4000 maxvalue 2147483647 no cycle;
create sequence group_id minvalue 4000 maxvalue 2147483647 no cycle;

create domain username_t varchar(31) check (
  value ~ '^[a-z][a-z0-9]+$'
);

-- auxiliary groups
create table "group" (
  "gid" integer primary key default nextval('group_id'),
  "name" username_t unique not null
);

alter sequence group_id owned by "group".gid;

create table "passwd" (
  "name" username_t unique not null,
  "uid" integer primary key default nextval('user_id'),
  "gid" integer not null references "group" (gid)
    on update cascade on delete cascade,
  "gecos" text, 
  -- Every user must have a default host for ssh/mail routing
  "host" integer not null references hosts (id),
  -- This could be any folder as we could also have bot users like 'git'
  "homeDir" text not null,
  "sshKeys" text[] not null
);

alter sequence user_id owned by passwd.uid;

create table "aux_groups" (
  "uid" int4 not null references passwd (uid) on delete cascade,
  "gid" int4 not null references "group"  (gid) on delete cascade,
  primary key ("uid", "gid")
);

-- prevent creation/update of a user if the number of users
-- in the group 'users' that have that host
-- is equal to the maxUsers for that host
insert into table "group" (name, id) values ('users', 3000);
create function check_max_users() returns trigger 
    language plpgsql as $$
    begin 
        if (tg_op = 'INSERT' or old.host <> new.host) and
           (select count(*) from passwd inner join aux_groups on (passwd.uid = aux_groups.uid and aux_groups.gid = 3000 and passwd.host = new.host)) >= (select maxUsers from hosts where hosts.id = new.host) then
            raise foreign_key_violation using message = 'maxUsers reached for host: '||new.host;
        end if;
        return new;
    end $$;
create constraint trigger max_users 
    after insert or update on passwd 
    for each row execute procedure check_max_users();

-- create role for creating new users
-- grant only rights to add new users
create role "write_users";
grant insert on table "group",passwd to "write_users";
grant select on table "hosts" to "write_users";
grant usage on sequence user_id,group_id to "write_users";
