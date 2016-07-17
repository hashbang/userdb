insert into hosts (name, ips) values ('testbox', ARRAY['192.13.3.134'::inet]);

insert into "group" (name) values ('testuser') returning gid;
insert into passwd (name, gid, host, "homeDir","sshKeys") values ('testuser', 4002, 1, '/home/testuser', ARRAY[]::text[]);

insert into "group" (name) values ('testuser2') returning gid;
insert into passwd (name, gid, host, "homeDir","sshKeys") values ('testuser2', 4003, 1, '/home/testuser2', ARRAY[]::text[]);
