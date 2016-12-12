-- -*- mode: sql; product: postgres -*-

-- hosts table
CREATE DOMAIN hostname_t text CHECK (
  VALUE ~ '^([a-z0-9]+\.)+hashbang\.sh$'
);

CREATE TABLE "hosts" (
  "name" hostname_t PRIMARY KEY,
  "maxusers" integer CHECK(maxusers >= 0),
  "data" jsonb -- extra data added in the stats answer
               -- conforms to the host_data.yaml schema
);

-- data for NSS' passwd
-- there is an implicit primary group for each user
-- UID and GID ranges conform to Debian policy:
--  https://www.debian.org/doc/debian-policy/ch-opersys.html#s9.2.2
CREATE SEQUENCE user_id MINVALUE 4000 MAXVALUE 59999 NO CYCLE;

CREATE DOMAIN username_t varchar(31) CHECK (
  VALUE ~ '^[a-z][a-z0-9]+$'
);

CREATE TABLE "passwd" (
  "uid" integer PRIMARY KEY
    CHECK((uid >= 1000 AND uid < 60000) OR (uid > 65535 AND uid < 4294967294))
    DEFAULT nextval('user_id'),
  "name" username_t UNIQUE NOT NULL,
  "host" text NOT NULL REFERENCES hosts (name),
  "homedir" text NOT NULL,
  "data" jsonb  -- conforms to the user_data.yaml schema
    CHECK(length(data::text) < 1048576) -- max 1M
);

alter sequence user_id owned by passwd.uid;

-- auxiliary groups
CREATE TABLE "group" (
  "gid" integer PRIMARY KEY CHECK(gid < 1000 OR (gid >= 60000 AND gid < 65000)),
  "name" username_t UNIQUE NOT NULL
);

CREATE TABLE "aux_groups" (
  "uid" int4 NOT NULL REFERENCES passwd  (uid) ON DELETE CASCADE,
  "gid" int4 NOT NULL REFERENCES "group" (gid) ON DELETE CASCADE,
  PRIMARY KEY ("uid", "gid")
);

-- prevent creation/update of a user if the number of users
-- in the group 'users' that have that host
-- is equal to the maxUsers for that host
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

-- create role for creating new users
-- grant only rights to add new users
create role "create_users";
grant insert on table "group",passwd to "create_users";
grant select on table "hosts" to "create_users";
grant usage on sequence user_id to "create_users";
