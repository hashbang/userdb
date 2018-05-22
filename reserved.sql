-- Aliases in our mail server configuration:
--  https://github.com/hashbang/admin-tools/blob/master/files/postfix/aliases.j2
--
-- This does not include common aliases defined by RFC 2142
\copy reserved_usernames (name) from './reserved/aliases';

-- List of reserved usernames by Geoffrey Thomas:
--   https://ldpreload.com/blog/names-to-reserve
\copy reserved_usernames (name) from './reserved/ldpreload.com';

-- Email aliases reserved by RFC 2142:
--  https://www.ietf.org/rfc/rfc2142.txt
\copy reserved_usernames (name) from './reserved/rfc2142';
