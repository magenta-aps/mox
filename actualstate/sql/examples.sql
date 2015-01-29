BEGIN;

DO $$
DECLARE brugerId UUID;
BEGIN
  -- Example call to create a user
  SELECT ID FROM ACTUAL_STATE_CREATE_BRUGER(
    ARRAY[
    -- BrugerEgenskaberType
      ROW (
    --   Virkning
        ROW (
          tstzrange(now(), 'infinity', '[]'),
          uuid_generate_v4(),
          'Bruger',
          'Note'
        )::Virkning,
        'BrugervendtNoegle', 'Brugernavn', 'Brugertype'
      )::BrugerEgenskaberType
    ],
    ARRAY[
  --     BrugerTilstandType
      ROW (
  --     Virkning
        ROW (
          tstzrange(now(), 'infinity', '[]'),
          uuid_generate_v4(),
          'Bruger',
          'Note'
        )::Virkning,
  --       Status
        'Aktiv'
      )::BrugerTilstandType
    ]
  ) INTO brugerId;

  PERFORM actual_state_read_bruger(brugerId,
                                         -- Virkning period
                                         TSTZRANGE('2015-01-20', 'infinity', '[]'),
                                         -- Registrering period
                                         TSTZRANGE(now(), 'infinity', '[]'),
                                         -- Cursor name
                                         'attributesCursor');
END
$$;

FETCH ALL IN "attributesCursor";

COMMIT;