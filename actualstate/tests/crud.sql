\i tests/pgtap.sql.lib

-- Start transaction and plan the tests.
BEGIN;

-- CREATE FUNCTION test.create_test_user() RETURNS Objekt AS $$
-- BEGIN
--   RETURN ;
-- END;
-- $$ LANGUAGE plpgsql;

CREATE FUNCTION test.test_create_bruger () RETURNS SETOF TEXT AS $$
DECLARE
  brugerID UUID;
BEGIN
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
      'Aktiv'
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
  ) INTO brugerID;

  DECLARE
    result BOOLEAN;
  BEGIN
    RETURN NEXT ok((SELECT COUNT(*) = 1 FROM Bruger WHERE ID = brugerID),
                   'One Bruger is inserted into Bruger table');
    RETURN NEXT ok((SELECT COUNT(*) = 0 FROM ONLY Objekt WHERE ID = brugerID),
                   'No Bruger is inserted directly into Objekt table');
  END;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION test.test_update_bruger () RETURNS SETOF TEXT AS $$
DECLARE
  brugerID UUID;
BEGIN
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
      'Aktiv'
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
  ) INTO brugerID;

  DECLARE
    reg Registrering;
  BEGIN
      -- Example call to update a user.
    SELECT * FROM ACTUAL_STATE_UPDATE(
        brugerID,
      ARRAY[]::EgenskaberType[],
      ARRAY[
        ROW (
          ROW ('[2015-01-01, 2015-01-05)'::TSTZRANGE,
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
          ROW ('[2015-01-30, infinity)'::TSTZRANGE,
            uuid_generate_v4(),
            'Bruger',
            'Note'
          )::Virkning,
          'Aktiv'
        )::TilstandsType
      ]
    ) INTO reg;
    DECLARE
      result BOOLEAN;
    BEGIN
      RETURN NEXT ok((SELECT COUNT(*) = 1 FROM Tilstand
        WHERE RegistreringsID = reg.ID
              AND (Virkning).TimePeriod = '[2015-01-10, 2015-01-20)'::TSTZRANGE
                     AND Status = 'Inaktiv'),
                     'Updated Bruger Tilstand got changed');
      RETURN NEXT ok((SELECT COUNT(*) = 1 FROM Tilstand
      WHERE RegistreringsID = reg.ID
            AND (Virkning).TimePeriod = '[2015-01-05, 2015-01-10)'::TSTZRANGE
                     AND Status = 'Aktiv'),
                     'Updated Bruger Tilstand''s old status'' range got changed');
    END;
--     Check that the properties got replaced
  END;
END;
$$ LANGUAGE plpgsql;



SELECT plan(4);

SELECT * FROM do_tap('test'::name);

-- Finish the tests and clean up.
SELECT * FROM finish();
COMMIT;
