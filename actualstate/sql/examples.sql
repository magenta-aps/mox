BEGIN;

DO $$
DECLARE brugerId UUID;
BEGIN
  -- Example call to create a user
  SELECT ID FROM ACTUAL_STATE_CREATE_BRUGER(
    ARRAY[
      ROW (
        ROW (
          '[2015-01-01, 2015-01-10)'::TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note'
        )::Virkning,
        'BrugervendtNoegle', 'Brugernavn', 'Brugertype'
      )::BrugerEgenskaberType,
      ROW (
        ROW (
          '[2015-01-10, 2015-01-20)'::TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note2'
        )::Virkning,
        'BrugervendtNoegle2', 'Brugernavn2', 'Brugertype2'
      )::BrugerEgenskaberType,
      ROW (
        ROW (
          '[2015-01-20, infinity)'::TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note3'
        )::Virkning,
        'BrugervendtNoegle3', 'Brugernavn3', 'Brugertype3'
      )::BrugerEgenskaberType
    ],
    ARRAY[
      ROW (
        ROW ('[2015-01-01, 2015-01-10)'::TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note'
        )::Virkning,
        'Aktiv'
      )::BrugerTilstandType,
      ROW (
        ROW ('[2015-01-10, 2015-01-20)'::TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note'
        )::Virkning,
        'Inaktiv'
      )::BrugerTilstandType,
      ROW (
        ROW ('[2015-01-20, infinity)'::TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note'
        )::Virkning,
        'Aktiv'
      )::BrugerTilstandType
    ]
  ) INTO brugerId;

  PERFORM actual_state_read_bruger(
      brugerId,
      -- Virkning period
      '[2015-01-01, 2015-01-15]'::TSTZRANGE,
      -- Registrering period
      TSTZRANGE(now(), 'infinity', '[]'),
      -- Cursor name
      'attributesCursor',
      'statesCursor'
  );
END
$$;

FETCH ALL IN "attributesCursor";
FETCH ALL IN "statesCursor";

COMMIT;