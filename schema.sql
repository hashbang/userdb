-- -*- mode: sql; product: postgres -*-

-- hosts table
create table "hosts" (
  "id" serial primary key,
  "name" text unique not null,
  "location" text,
  -- 4326 is the EPSG standard for lat/lon
  "coordinates" geography (point, 4326),
  "maxUsers" integer check (maxUsers >= 0),
  "ips" inet[] not null
)

-- data for NSS' passwd
-- there is an implicit primary group for each user
create sequence user_id minvalue 4000 maxvalue 2147483647 no cycle;

create domain username_t varchar(31) check (
  value ~ '^[a-z][a-z0-9]+$'
);

-- auxiliary groups
create table "group" (
  "gid" integer primary key maxvalue 999,
  "name" username_t unique not null,
);

create table "passwd" (
  "name" username_t unique not null,
  "uid" integer primary key minvalue 1000 default nextval('user_id'),
  "gid" integer not null references "group" (gid)
    on update cascade on delete cascade,
  "gecos" text, 
  -- Every user must have a default host for ssh/mail routing
  "host" integer not null references hosts (id),
  -- This could be any folder as we could also have bot users like 'git'
  "homeDir" text not null,
  "sshKeys" text[] not null,
);

create table "aux_groups" (
  "uid" int4 not null references passwd (uid) on delete cascade,
  "gid" int4 not null references group  (gid) on delete cascade,
  primary key ("uid", "gid"),
);
