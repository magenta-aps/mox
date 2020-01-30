-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


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
