-- -*- mode: sql; product: postgres -*-

-- hosts table
CREATE TABLE "hosts" (
  "id" serial PRIMARY KEY,
  "name" text UNIQUE NOT NULL,
  "maxusers" integer CHECK(maxusers >= 0),
  "data" jsonb -- extra data added in the stats answer
               -- conforms to the host_data.yaml schema
);

-- data for NSS' passwd
-- there is an implicit primary group for each user
CREATE SEQUENCE user_id MINVALUE 4000 MAXVALUE 2147483647 NO CYCLE;

CREATE DOMAIN username_t varchar(31) CHECK (
  VALUE ~ '^[a-z][a-z0-9]+$'
);

CREATE TABLE "passwd" (
  "uid" integer PRIMARY KEY CHECK(uid >= 1000) DEFAULT nextval('user_id'),
  "name" username_t UNIQUE NOT NULL,
  "host" integer NOT NULL REFERENCES hosts (id),
  "homedir" text NOT NULL,
  "data" jsonb  -- conforms to the user_data.yaml schema
);

alter sequence user_id owned by passwd.uid;

-- auxiliary groups
CREATE TABLE "group" (
  "gid" integer PRIMARY KEY CHECK(gid < 1000),
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
	   (select count(*) from passwd where passwd.host = new.host) >= (select "maxusers" from hosts where hosts.id = new.host) then
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
