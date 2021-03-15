# #! User Database #

<http://github.com/hashbang/userdb>

[![TravisCI][travis-badge]][travis-status]
[![IRC][irc-badge]][irc]
[![PostgreSQL][postgresql-badge]][postgresql]
[![License][license-badge]][license-status]

[postgresql-badge]: https://img.shields.io/badge/postgresql-9.4-blue.svg
[postgresql]: https://www.postgresql.org/docs/9.4/static/index.html
[irc-badge]: https://img.shields.io/badge/irc-%23%21%20on%20hashbang-blue.svg
[irc]: https://webirc.hashbang.sh/
[travis-badge]: https://travis-ci.org/hashbang/userdb.svg?branch=master
[travis-status]: https://travis-ci.org/hashbang/userdb
[license-badge]: https://img.shields.io/github/license/hashbang/userdb.svg
[license-status]: LICENSE.md

## About ##

This repo contains the schema, design and requirements for our
PostgreSQL-based user database.

## Requirements ##

  - PostgreSQL 9.4+

## Installation ##

This will setup userdb as the `userdb` database on a local PostgreSQL.

```
make install
```

## Development ##

Drops you into a fresh PostgreSQL shell with latest schema:

```
make develop
```

## Testing ##

```
make test
```

## Contribution ##

Please consider the following when submitting contributions:

  - Observe the [Design Requirements].
  - Update the [Design Documentation] whenever designing new features
	or modifying their implementation.
  - Use Pull Requests for all changes.
  - Pull Requests are only merged when all tests pass **when merged with
	master**. This is [the “not rocket science” rule] of software.
  - When designing new features, add tests for them right away.

Feel free to reach out to us with ideas or to get help contributing. We
are totally happy with something taking longer to do, if you learn
something in the process. It is the reason #! exists.

[Design Requirements]:  docs/REQUIREMENTS.md
[Design Documentation]: docs/DESIGN.md
[the “not rocket science” rule]: https://graydon2.dreamwidth.org/1597.html

## Notes ##

Questions/Comments?

Please learn and reach out to us via the following:

  - IRC: [ircs://irc.hashbang.sh:6697/#!](https://chat.hashbang.sh)
  - E-Mail: [team@hashbang.sh](mailto:team@hashbang.sh)
  - Issue Tracker:  <https://github.com/hashbang/hashbang/issues>
  - Documentation:  <https://github.com/hashbang/hashbang>
  - Shell Services: <https://hashbang.sh>
