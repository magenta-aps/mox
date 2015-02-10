-- Example call to create a user
SELECT ID FROM ACTUAL_STATE_CREATE(
  'Bruger',
  ARRAY[
    ROW (
      ARRAY[
        ROW(
          'Brugernavn',
          'Brugernavn'
        )::EgenskabsType,
        ROW(
          'Brugertype',
          'Brugertype'
        )::EgenskabsType
      ],
      ROW (
        '[2015-01-01, 2015-01-10)'::TSTZRANGE,
        uuid_generate_v4(),
        'Bruger',
        'Note'
      )::Virkning,
      'BrugervendtNoegle'
    )::EgenskaberType,
    ROW (
      ARRAY[
        ROW(
          'Brugernavn',
          'Brugernavn2'
        )::EgenskabsType,
        ROW(
          'Brugertype',
          'Brugertype2'
        )::EgenskabsType
      ],
      ROW (
        '[2015-01-10, 2015-01-20)'::TSTZRANGE,
        uuid_generate_v4(),
        'Bruger',
        'Note2'
      )::Virkning,
     'BrugervendtNoegle2'
    )::EgenskaberType,
    ROW (
      ARRAY[
        ROW(
          'Brugernavn',
          'Brugernavn3'
        )::EgenskabsType,
        ROW(
          'Brugertype',
          'Brugertype3'
        )::EgenskabsType
      ],
      ROW (
        '[2015-01-20, infinity)'::TSTZRANGE,
        uuid_generate_v4(),
        'Bruger',
        'Note3'
      )::Virkning,
      'BrugervendtNoegle3'
    )::EgenskaberType
  ],
  ARRAY[
    ROW (
      ROW ('[2015-01-01, 2015-01-10)'::TSTZRANGE,
        uuid_generate_v4(),
        'Bruger',
        'Note'
      )::Virkning,
      'Aktiv'
    )::TilstandsType,
    ROW (
      ROW ('[2015-01-10, 2015-01-20)'::TSTZRANGE,
        uuid_generate_v4(),
        'Bruger',
        'Note'
      )::Virkning,
      'Inaktiv'
    )::TilstandsType,
    ROW (
      ROW ('[2015-01-20, infinity)'::TSTZRANGE,
        uuid_generate_v4(),
        'Bruger',
        'Note'
      )::Virkning,
      'Aktiv'
    )::TilstandsType
  ]
);

  -- Example call to update a user.
  -- Assumes there is only one user in the system
SELECT ACTUAL_STATE_UPDATE(
    (SELECT ID FROM Bruger LIMIT 1),
  ARRAY[
    ROW (
      ARRAY[
        ROW(
          'Brugernavn',
          'Brugernavn'
        )::EgenskabsType,
        ROW(
          'Brugertype',
          'Brugertype'
        )::EgenskabsType
      ],
      ROW (
        '[2015-01-01, 2015-01-10)'::TSTZRANGE,
        uuid_generate_v4(),
        'Bruger',
        'Note'
      )::Virkning,
      'BrugervendtNoegle'
    )::EgenskaberType,
    ROW (
      ARRAY[
        ROW(
          'Brugernavn',
          'Brugernavn2changed'
        )::EgenskabsType,
        ROW(
          'Brugertype',
          'Brugertype2changed'
        )::EgenskabsType
      ],
      ROW (
        '[2015-01-10, 2015-01-20)'::TSTZRANGE,
        uuid_generate_v4(),
        'Bruger',
        'Note2'
      )::Virkning,
     'BrugervendtNoegle2'
    )::EgenskaberType,
    ROW (
      ARRAY[
        ROW(
          'Brugernavn',
          'Brugernavn3changed'
        )::EgenskabsType,
        ROW(
          'Brugertype',
          'Brugertype3changed'
        )::EgenskabsType
      ],
      ROW (
        '[2015-01-20, infinity)'::TSTZRANGE,
        uuid_generate_v4(),
        'Bruger',
        'Note3'
      )::Virkning,
      'BrugervendtNoegle3changed'
    )::EgenskaberType
  ],
  ARRAY[
    ROW (
      ROW ('[2015-01-01, 2015-01-10)'::TSTZRANGE,
        uuid_generate_v4(),
        'Bruger',
        'Note'
      )::Virkning,
      'Aktiv'
    )::TilstandsType,
    ROW (
      ROW ('[2015-01-10, 2015-01-20)'::TSTZRANGE,
        uuid_generate_v4(),
        'Bruger',
        'Note'
      )::Virkning,
      'Inaktiv'
    )::TilstandsType,
    ROW (
      ROW ('[2015-01-20, infinity)'::TSTZRANGE,
        uuid_generate_v4(),
        'Bruger',
        'Note'
      )::Virkning,
      'Aktiv'
    )::TilstandsType
  ]
);

-- Reading from cursors must be inside a transaction
BEGIN;
  SELECT ACTUAL_STATE_READ(
      'Bruger',
      (SELECT ID FROM Bruger LIMIT 1),
      -- Virkning period
      '[2015-01-01, 2015-01-15]'::TSTZRANGE,
      -- Registrering period
      TSTZRANGE(now(), 'infinity', '[]'),
      -- Cursor name
      'attributesCursor',
      'statesCursor'
  );

  FETCH ALL FROM "attributesCursor";
  FETCH ALL FROM "statesCursor";
COMMIT;
--
-- SELECT * FROM BrugerRegistrering;
--
-- SELECT ACTUAL_STATE_DELETE_BRUGER((SELECT ID FROM Bruger LIMIT 1));
--
-- SELECT ACTUAL_STATE_PASSIVE_BRUGER((SELECT ID FROM Bruger LIMIT 1));
--
-- SELECT * FROM brugeregenskaber;