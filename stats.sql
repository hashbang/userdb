-- -*- mode: sql; sql-product: postgres -*-

-- Create the host statistics view
-- This is what the statistics API endpoint must expose, formated as JSON.
create view host_statistics as
  select name, users, maxusers, data
    from hosts
    join (
            select count(1) as users,
             host
              from passwd
          group by host
         )
      as count
      on (count.host = hosts.name)
;
