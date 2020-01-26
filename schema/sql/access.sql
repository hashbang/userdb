-- -*- mode: sql; sql-product: postgres -*-

create user "ssh_auth" inherit;
comment on role "ssh_auth" is
    $$Access for ssh via AuthorizedKeysCommand$$;
alter role "ssh_auth" with login;
grant select on table
    public."group",
    public."passwd",
    public."aux_groups"
to "ssh_auth";

create user "mail" inherit;
comment on role "mail" is
    $$Access for MTAs like Postfix$$;
alter role "mail" with login;
