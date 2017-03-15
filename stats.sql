-- -*- mode: sql; sql-product: postgres -*-

-- Create the host statistics view
-- This is what the statistics API endpoint must expose, formated as JSON.
CREATE VIEW host_statistics AS
  SELECT name, users, maxusers, data
    FROM hosts
    JOIN (
            SELECT COUNT(1) AS users,
	           host
              FROM passwd
          GROUP BY host
         )
      AS count
      ON (count.host = hosts.name)
;
