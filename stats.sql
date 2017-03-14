-- -*- mode: sql; sql-product: postgres -*-

-- Create the statistics view
-- This is what the statistics API endpoint must expose, formated as JSON.
CREATE VIEW statistics AS
  SELECT name, users, maxusers, data
    FROM hosts
    JOIN (
            SELECT COUNT(*) AS users,
	           host
              FROM passwd
          GROUP BY host
         )
      AS count
      ON (count.host = hosts.name)
;
