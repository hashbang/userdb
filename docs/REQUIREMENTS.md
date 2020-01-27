# #! User Database -- Requirements #

See <http://github.com/hashbang/userdb>

# About

This document describes the requirements for our user database.
Understanding the design goals is an important part of understanding the
engineering trade-offs made there.

# Data

A user has several kinds of associated data:
- relational data, which might be involved in `WHERE` conditions or `JOIN`s:
  `uid`, `gid`, `username` and `host`;
- non-relational data: SSH keys, full name, preferred shell, ...
- users may add additional data without specific cooperation from the #! admins,
  facilitating the construction of new, non-core services
  (finger, GPG key discovery, ...)

Each user has a primary group, that shares the same id and name.

Administrators may define auxiliary groups (such as `adm` or `sudo`)
and any user can belong to any number of auxiliary groups.

Lastly, the DB needs to keep track of per-server information, namely its
`hostname`, IP address and location.  This is in part intended for consumption
by the [stats API](https://hashbang.sh/server/stats).


# Properties

## Immediate

These requirements **must** be achieved before deployment:

- Availability
  - Users do not lose access to the shell servers if part of the infra goes down.
  - Loss of any part of the infrastructure is recoverable with limited data loss.

- Consistency
  - Changes in the userdb must occur in some coherent ordering, and reads must
	respect it.  In particular, it is not possible to observe partial updates.
  - The data held in the database must be internally coherent: for instance,
	a user may not belong to a group that does not exist.

- Maintainability
  - Avoid custom implementations of standard modules (NSS, PAM, ...)
	whenever possible and reasonable.
  - Minimize the amount of components that have knowledge of the database
	implementation, and make the others rely on a more abstract API.

- Privilege separation
  - All data must be non-readable, non-writeable, by default.
  - Each service/component must have the least possible access (read, write, ...),
	restricted to the data it needs to manipulate.

- No-downtime deployment
  - The initial deployment must be achievable without disrupting core services
	(shell access, IRC, ...), and must minimize the disruption to auxiliary
	services (mail, ...).
  - Any later update/maintainance of the system must be achievable without
	disrupting read-availability of the user DB.  Having a short window where
	users cannot edit their records or signup is acceptable.


## Long-term

These requirements **must** be *achievable*:

- Privilege separation
  - Unprivileged `hashbangctl` can only modify the user's own data
- Remote service authentication: local (shell) users should be able to authenticate
  transparently and securely to remote (#!) services (SMTP, IRC, ...).


# Services

The following services need to interact with the user DB:
- OpenSSH, through `AuthorizedKeysCommand`;
- `mail.hashbang.sh` needs to extract host info for mail routing;
- `hashbang.sh` needs to extract statistics;
- user creation.
