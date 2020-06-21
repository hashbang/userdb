-- label_value can be any sequence of UTF-8 characters, but the backslash (\),
-- double-quote ("), and line feed (\n) characters have to be escaped as \\,
-- \", and \n, respectively.
create function escape_label(text) returns text
    language sql as $$
    select regexp_replace($1, E'[\\"\n]', '\\\&', 'g');
    $$
    immutable;

create view v1.metrics as
    select 'hosts.count' as metric, count(*) as "value" from hosts
    union select 'passwd.count' as metric, count(*) as "value" from passwd
    union select 'passwd.count{shell="' || escape_label(data->>'shell') || '"}' as metric, count(*) as "value" from passwd
        group by data->>'shell'
    union select 'passwd.count{host="' || escape_label(host) || '"}' as metric, count(*) as "value" from passwd
        group by host
    union select 'groups.count{group="' || escape_label("group".name) || '"}' as metric, count(*) as "value" from aux_groups
        join "group" on "group".gid = aux_groups.gid
        group by "group".name;
alter view v1."metrics" owner to api;
grant select on table v1."metrics" to "api-anon";

create function v1.metrics() returns text
    language sql as $$
    select string_agg(metric || ' ' || "value" || ' ' || (extract(epoch from current_timestamp) * 1000)::bigint, E'\n') from v1.metrics;
    $$
    stable;
comment on function v1.metrics() is
    $$Metrics for ingestion by Prometheus$$;
