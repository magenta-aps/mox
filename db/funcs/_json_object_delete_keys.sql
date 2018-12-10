-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.


CREATE OR REPLACE FUNCTION actual_state._json_object_delete_keys(json json, keys_to_delete TEXT[])
  RETURNS json
  LANGUAGE sql
  IMMUTABLE
  STRICT
AS $function$
SELECT COALESCE(
  (SELECT ('{' || string_agg(to_json(key) || ':' || value::json::text, ',') || '}')
   FROM json_each(json)
   WHERE key not in (select key from unnest(keys_to_delete) as a(key))),
  '{}'
)::json
$function$;
