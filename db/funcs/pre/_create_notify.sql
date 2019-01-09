-- Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.


CREATE OR REPLACE FUNCTION notify_event ()
    RETURNS TRIGGER AS $$
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
    -- Contruct the notification
    notification = json_build_object('table', TG_TABLE_NAME, 'action', TG_OP, 'data', data);
    -- Execute pg_notify(channel, notification)
    PERFORM
        pg_notify('mox_notifications', notification::text);
    -- Result is ignored since this is an AFTER trigger
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

