BEGIN;

DO $$
DECLARE brugerId UUID;
BEGIN
  -- Example call to create a user
  SELECT ID FROM ACTUAL_STATE_CREATE_BRUGER(
    ARRAY[
      ROW (
        ROW (
          tstzrange('2015-01-01', '2015-01-10', '[)'),
          uuid_generate_v4(),
          'Bruger',
          'Note'
        )::Virkning,
        'BrugervendtNoegle', 'Brugernavn', 'Brugertype'
      )::BrugerEgenskaberType,
      ROW (
        ROW (
          tstzrange('2015-01-10', '2015-01-20', '[)'),
          uuid_generate_v4(),
          'Bruger',
          'Note2'
        )::Virkning,
        'BrugervendtNoegle2', 'Brugernavn2', 'Brugertype2'
      )::BrugerEgenskaberType,
      ROW (
        ROW (
          tstzrange('2015-01-20', 'infinity', '[]'),
          uuid_generate_v4(),
          'Bruger',
          'Note3'
        )::Virkning,
        'BrugervendtNoegle3', 'Brugernavn3', 'Brugertype3'
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
                                         TSTZRANGE('2015-01-01',
                                                   '2015-01-15', '[]'),
                                         -- Registrering period
                                         TSTZRANGE(now(), 'infinity', '[]'),
                                         -- Cursor name
                                         'attributesCursor');
END
$$;

FETCH ALL IN "attributesCursor";

COMMIT;