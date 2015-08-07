-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

CREATE OR REPLACE FUNCTION actual_state._amqp_publish_notification
(objekttype varchar, operation varchar, objekt_uuid uuid)
RETURNS bool
AS 
$$
  -- Publish to broker ID 1, to exchange mox.notifications, with empty
  -- routing key, empty body
  SELECT amqp.publish(1, 'mox.notifications', '', '',
    ARRAY[
      ARRAY['beskedtype', 'Notification'],
      ARRAY['objekttype', objekttype],
      ARRAY['operation', operation],
      ARRAY['uuid', objekt_uuid::varchar]
    ],
    'application/json')
$$ LANGUAGE sql immutable;
