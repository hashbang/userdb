-- -*- mode: sql; product: postgres -*-

-- Trick to make a generic notifier, “stolen” and adapted from
--   https://coussej.github.io/2015/09/15/Listening-to-generic-JSON-notifications-from-PostgreSQL-in-Go/
--
-- This assumes that the notification channel is called after its table
CREATE OR REPLACE FUNCTION notify_change() RETURNS TRIGGER AS $$
    DECLARE
        data json;
        notification json;

    BEGIN
        -- Convert the old or new row to JSON, based on the kind of action.
        -- Action = DELETE?             -> OLD row
        -- Action = INSERT or UPDATE?   -> NEW row
        IF (TG_OP = 'DELETE') THEN
            data = row_to_json(OLD);
        ELSE
            data = row_to_json(NEW);
        END IF;

        -- Contruct the notification as a JSON string.
        notification = json_build_object('action', TG_OP,
                                         'data',   data);


        -- Execute pg_notify(channel, notification)
        PERFORM pg_notify(TG_TABLE_NAME, notification::text);

        -- Result is ignored since this is an AFTER trigger
        RETURN NULL;
    END;
$$ LANGUAGE plpgsql;


-- Make table hosts notify-able
CREATE TRIGGER notify_hosts_change
AFTER INSERT OR UPDATE OR DELETE ON hosts
    FOR EACH ROW EXECUTE PROCEDURE notify_change();


-- Make table passwd notify-able
CREATE TRIGGER notify_passwd_change
AFTER INSERT OR UPDATE OR DELETE ON passwd
    FOR EACH ROW EXECUTE PROCEDURE notify_change();
