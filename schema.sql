-- -*- mode: sql; product: postgres -*-

-- hosts table
CREATE TABLE "hosts" (
  "id" serial PRIMARY KEY,
  "name" text UNIQUE NOT NULL,
  "location" text,
  -- 4326 is the EPSG standard for lat/lon
  "coordinates" geography (point, 4326),
  "maxUsers" integer check (maxUsers >= 0),
  "ips" inet[] not null
)

-- data for NSS' passwd
-- there is an implicit primary group for each user
CREATE SEQUENCE user_id MINVALUE 4000 MAXVALUE 2147483647 NO CYCLE;

CREATE DOMAIN username_t varchar(31) CHECK (
  VALUE ~ '^[a-z][a-z0-9]+$'
);

-- auxiliary groups
CREATE TABLE "group" (
  "gid" integer PRIMARY KEY MAXVALUE 999,
  "name" username_t UNIQUE NOT NULL,
);

CREATE TABLE "passwd" (
  "name" username_t UNIQUE NOT NULL,
  "uid" integer PRIMARY KEY MINVALUE 1000 DEFAULT nextval('user_id'),
  "gid" integer not null references "group" (gid)
    on update cascade on delete cascade,
  "gecos" text, 
  -- Every user must have a default host for ssh/mail routing
  "host" integer not null REFERENCES hosts (id),
  -- This could be any folder as we could also have bot users like 'git'
  "homeDir" text NOT NULL,
  "sshKeys" text[] not null,
);

CREATE TABLE "aux_groups" (
  "uid" int4 NOT NULL REFERENCES passwd (uid) ON DELETE CASCADE,
  "gid" int4 NOT NULL REFERENCES group  (gid) ON DELETE CASCADE,
  PRIMARY KEY ("uid", "gid"),
);
