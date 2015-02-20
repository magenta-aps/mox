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
  SELECT ID
  FROM ACTUAL_STATE_CREATE(
      'Bruger',
      ARRAY [
        ROW (
        'Egenskab',
        ARRAY [
          ROW (
          ARRAY [
            ROW ('BrugervendtNoegle', 'BrugervendtNoegle'),
            ROW ('Brugernavn', 'Brugernavn'),
            ROW ('Brugertype', 'Brugertype')
          ] :: AttributFeltType [],
          ROW ('[2015-01-01, 2015-01-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note'
          ) :: Virkning
        ) :: AttributType,
          ROW (
          ARRAY [
            ROW ('BrugervendtNoegle', 'BrugervendtNoegle2'),
            ROW ('Brugernavn', 'Brugernavn2'),
            ROW ('Brugertype', 'Brugertype2')
          ] :: AttributFeltType [],
          ROW ('[2015-01-10, 2015-01-20)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note2'
          ) :: Virkning
        ) :: AttributType,
          ROW (
          ARRAY [
            ROW ('BrugervendtNoegle', 'BrugervendtNoegle3'),
            ROW ('Brugernavn', 'Brugernavn3'),
            ROW ('Brugertype', 'Brugertype3')
          ] :: AttributFeltType [],
          ROW ('[2015-01-20, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note3'
          ) :: Virkning
        ) :: AttributType
        ]
        ) :: AttributterType
      ],
      ARRAY [
        ROW (
        'Gyldighed',
        ARRAY [
          ROW (
          ROW ('[2015-01-01, 2015-01-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note'
          ) :: Virkning,
          'Aktiv'
        ),
          ROW (
          ROW ('[2015-01-10, 2015-01-20)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note'
          ) :: Virkning,
          'Aktiv'
        ),
          ROW (
          ROW ('[2015-01-20, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note'
          ) :: Virkning,
          'Aktiv'
        )
        ] :: TilstandType []
      ) :: TilstandeType
      ],

      ARRAY [
        ROW (
        'Adresser',
        ARRAY [
          ROW (
          ROW ('[2015-01-20, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note'
          ) :: Virkning,
          ARRAY [uuid_generate_v4()]
        ) :: RelationType
        ]
      ) :: RelationerType
      ]
  )
  INTO brugerID;

  DECLARE
    result BOOLEAN;
  BEGIN
    RETURN NEXT ok((SELECT COUNT(*) = 1
                    FROM Bruger
                    WHERE ID = brugerID),
                   'One Bruger is inserted into Bruger table');
    RETURN NEXT ok((SELECT COUNT(*) = 0
                    FROM ONLY Objekt
                    WHERE ID = brugerID),
                   'No Bruger is inserted directly into Objekt table');
  END;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION test.get_test_property (
  old BOOLEAN,
  n INT,
  TimePeriod  TSTZRANGE
) RETURNS AttributType AS $$
DECLARE
--   Construct a prefix, e.g. O1, O2... for old or N1, N2.. for new
  prefix TEXT := (CASE WHEN old THEN 'O' ELSE 'N' END) || n::TEXT;
  fields AttributFeltType[];
BEGIN
  IF old THEN
    fields := ARRAY [
      ROW ('BrugervendtNoegle', prefix || 'BrugervendtNoegle'),
--       Leave out the Brugernavn so we can check that merging works
      ROW ('Brugertype', prefix || 'Brugertype' )
    ] :: AttributFeltType [];
  ELSE
    fields := ARRAY [
      ROW ('BrugervendtNoegle', prefix || 'BrugervendtNoegle'),
      ROW ('Brugernavn', prefix || 'Brugernavn')
--       Leave out the Brugertype so we can check that merging works
    ] :: AttributFeltType [];
  END IF;
  RETURN ROW (
      fields,
      ROW (TimePeriod,
        uuid_generate_v4(),
        'Bruger',
        'Note'
      ) :: Virkning
  ) :: AttributType;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION test.test_update_bruger () RETURNS SETOF TEXT AS $$
DECLARE
  brugerID UUID;
  oldRelUUID UUID[] = ARRAY[uuid_generate_v4(), uuid_generate_v4()];
  newRelUUID UUID[] = ARRAY[uuid_generate_v4(), uuid_generate_v4()];
BEGIN
  SELECT ID FROM ACTUAL_STATE_CREATE(
      'Bruger',
      ARRAY [
        ROW (
        'Egenskab',
        ARRAY [
          test.get_test_property(TRUE, 1, '[2015-01-15, 2015-01-20)' :: TSTZRANGE),
          test.get_test_property(TRUE, 2, '[2015-02-05, 2015-02-20)' :: TSTZRANGE),
          test.get_test_property(TRUE, 3, '[2015-03-01, 2015-03-10)' :: TSTZRANGE),
          test.get_test_property(TRUE, 4, '[2015-04-01, 2015-04-20)' :: TSTZRANGE),
          test.get_test_property(TRUE, 5, '[2015-05-05, 2015-05-10)' :: TSTZRANGE),
          test.get_test_property(TRUE, 6, '[2015-06-05, 2015-06-10)' :: TSTZRANGE),
          test.get_test_property(TRUE, 7, '[2015-06-15, 2015-06-20)' :: TSTZRANGE),
          test.get_test_property(TRUE, 8, '[2015-07-01, 2015-07-25)' :: TSTZRANGE),
          test.get_test_property(TRUE, 9, '[2015-08-01, 2015-08-20)' :: TSTZRANGE),
          test.get_test_property(TRUE, 10, '[2015-09-05, 2015-09-20)' :: TSTZRANGE),
          test.get_test_property(TRUE, 11, '[2015-10-01, 2015-10-10)' :: TSTZRANGE),
          test.get_test_property(TRUE, 12, '[2015-10-15, 2015-10-25)' :: TSTZRANGE),
          test.get_test_property(TRUE, 13, '[2015-11-01, 2015-11-10)' :: TSTZRANGE),
          test.get_test_property(TRUE, 14, '[2015-11-10, 2015-11-20)' :: TSTZRANGE)
        ]
        ) :: AttributterType
      ],
      ARRAY [
        ROW (
        'Gyldighed',
        ARRAY [
          ROW (
          ROW ('[2014-12-01, 2014-12-15)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note'
          ) :: Virkning,
          'Aktiv'
        ),
          ROW (
          ROW ('[2015-01-01, 2015-01-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note'
          ) :: Virkning,
          'Aktiv'
        ),
          ROW (
          ROW ('[2015-01-10, 2015-01-20)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note'
          ) :: Virkning,
          'Aktiv'
        ),
          ROW (
          ROW ('[2015-01-20, 2015-01-30)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note'
          ) :: Virkning,
          'Aktiv'
        ),
          ROW (
          ROW ('[2015-01-30, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note'
          ) :: Virkning,
          'Aktiv'
        )
        ] :: TilstandType []
      ) :: TilstandeType
      ],

      ARRAY [
        ROW (
        'Adresser',
        ARRAY [
          ROW (
          ROW ('[2015-01-20, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note'
          ) :: Virkning,
          oldRelUUID
        ) :: RelationType
        ]
      ) :: RelationerType
      ]
  )
  INTO brugerID;

  DECLARE
    reg Registrering;
  BEGIN
      -- Example call to update a user.
    SELECT * FROM ACTUAL_STATE_UPDATE(
        brugerID,
        ARRAY [
          ROW (
          'Egenskab',
          ARRAY [
            test.get_test_property(FALSE, 1, '[2015-01-01, 2015-01-10)' :: TSTZRANGE),
            test.get_test_property(FALSE, 2, '[2015-02-01, 2015-02-10)' :: TSTZRANGE),
            test.get_test_property(FALSE, 3, '[2015-03-05, 2015-03-20)' :: TSTZRANGE),
            test.get_test_property(FALSE, 4, '[2015-04-05, 2015-04-10)' :: TSTZRANGE),
            test.get_test_property(FALSE, 5, '[2015-05-01, 2015-05-20)' :: TSTZRANGE),
            test.get_test_property(FALSE, 6, '[2015-06-01, 2015-06-25)' :: TSTZRANGE),
            test.get_test_property(FALSE, 7, '[2015-07-05, 2015-07-10)' :: TSTZRANGE),
            test.get_test_property(FALSE, 8, '[2015-07-15, 2015-07-20)' :: TSTZRANGE),
            test.get_test_property(FALSE, 9, '[2015-08-01, 2015-08-20)' :: TSTZRANGE),
            test.get_test_property(FALSE, 10, '[2015-09-01, 2015-09-10)' :: TSTZRANGE),
            test.get_test_property(FALSE, 11, '[2015-09-15, 2015-09-25)' :: TSTZRANGE),
            test.get_test_property(FALSE, 12, '[2015-10-05, 2015-10-20)' :: TSTZRANGE),
            test.get_test_property(FALSE, 13, '[2015-11-01, 2015-11-10)' :: TSTZRANGE),
            test.get_test_property(FALSE, 14, '[2015-11-10, 2015-11-20)' :: TSTZRANGE)
          ]
        ) :: AttributterType
        ],
        ARRAY [
          ROW (
          'Gyldighed',
          ARRAY [
            ROW (
            ROW ('[2014-11-01, 2014-12-20)' :: TSTZRANGE,
            uuid_generate_v4(),
            'Bruger',
            'Note2'
            ) :: Virkning,
            'Aktiv'
          ),
            ROW (
            ROW ('[2015-01-03, 2015-01-05)' :: TSTZRANGE,
            uuid_generate_v4(),
            'Bruger',
            'Note2'
            ) :: Virkning,
            'Aktiv'
          ),
            ROW (
            ROW ('[2015-01-10, 2015-01-20)' :: TSTZRANGE,
            uuid_generate_v4(),
            'Bruger',
            'Note'
            ) :: Virkning,
            'Inaktiv'
          ),
            ROW (
            ROW ('[2015-01-25, 2015-02-10)' :: TSTZRANGE,
            uuid_generate_v4(),
            'Bruger',
            'Note2'
            ) :: Virkning,
            'Aktiv'
          )
          ] :: TilstandType []
        ) :: TilstandeType
        ],

        ARRAY [
          ROW (
          'Adresser',
          ARRAY [
            ROW (
            ROW ('[2015-01-20, infinity)' :: TSTZRANGE,
            uuid_generate_v4(),
            'Bruger',
            'Note'
            ) :: Virkning,
            newRelUUID
          ) :: RelationType
          ]
        ) :: RelationerType
        ]
    ) INTO reg;

--     These are the expected results of the attribut update
--     This was produced by doing the following:
--     From a psql shell:
--        select af.name, af.value, (at.virkning).timeperiod into
-- expected_attribut_results from attributfelt af JOIN attribut at ON
-- af.AttributID = at.ID JOIN attributter att ON at.AttributterID = att.ID WHERE att.registreringsid = 3;
--
-- Then:
--   sudo -u postgres pg_dump -t expected_attribut_results --inserts mox >results.sql

    CREATE TEMPORARY TABLE expected_attribut_results (
      name text,
      value text,
      timeperiod tstzrange
    );

    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N1Brugernavn', '["2015-01-01 00:00:00+01","2015-01-10 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N1BrugervendtNoegle', '["2015-01-01 00:00:00+01","2015-01-10 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O1Brugertype', '["2015-01-15 00:00:00+01","2015-01-20 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'O1BrugervendtNoegle', '["2015-01-15 00:00:00+01","2015-01-20 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N2Brugernavn', '["2015-02-01 00:00:00+01","2015-02-05 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N2BrugervendtNoegle', '["2015-02-01 00:00:00+01","2015-02-05 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O2Brugertype', '["2015-02-05 00:00:00+01","2015-02-10 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N2Brugernavn', '["2015-02-05 00:00:00+01","2015-02-10 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N2BrugervendtNoegle', '["2015-02-05 00:00:00+01","2015-02-10 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O2Brugertype', '["2015-02-10 00:00:00+01","2015-02-20 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'O2BrugervendtNoegle', '["2015-02-10 00:00:00+01","2015-02-20 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O3Brugertype', '["2015-03-01 00:00:00+01","2015-03-05 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'O3BrugervendtNoegle', '["2015-03-01 00:00:00+01","2015-03-05 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O3Brugertype', '["2015-03-05 00:00:00+01","2015-03-10 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N3BrugervendtNoegle', '["2015-03-05 00:00:00+01","2015-03-10 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N3Brugernavn', '["2015-03-05 00:00:00+01","2015-03-10 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N3Brugernavn', '["2015-03-10 00:00:00+01","2015-03-20 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N3BrugervendtNoegle', '["2015-03-10 00:00:00+01","2015-03-20 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O4Brugertype', '["2015-04-01 00:00:00+02","2015-04-05 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'O4BrugervendtNoegle', '["2015-04-01 00:00:00+02","2015-04-05 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N4Brugernavn', '["2015-04-05 00:00:00+02","2015-04-10 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N4BrugervendtNoegle', '["2015-04-05 00:00:00+02","2015-04-10 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O4Brugertype', '["2015-04-05 00:00:00+02","2015-04-10 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O4Brugertype', '["2015-04-10 00:00:00+02","2015-04-20 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'O4BrugervendtNoegle', '["2015-04-10 00:00:00+02","2015-04-20 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N5Brugernavn', '["2015-05-01 00:00:00+02","2015-05-05 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N5BrugervendtNoegle', '["2015-05-01 00:00:00+02","2015-05-05 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N5Brugernavn', '["2015-05-05 00:00:00+02","2015-05-10 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O5Brugertype', '["2015-05-05 00:00:00+02","2015-05-10 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N5BrugervendtNoegle', '["2015-05-05 00:00:00+02","2015-05-10 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N5Brugernavn', '["2015-05-10 00:00:00+02","2015-05-20 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N5BrugervendtNoegle', '["2015-05-10 00:00:00+02","2015-05-20 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N6Brugernavn', '["2015-06-01 00:00:00+02","2015-06-05 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N6BrugervendtNoegle', '["2015-06-01 00:00:00+02","2015-06-05 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N6BrugervendtNoegle', '["2015-06-05 00:00:00+02","2015-06-10 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O6Brugertype', '["2015-06-05 00:00:00+02","2015-06-10 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N6Brugernavn', '["2015-06-05 00:00:00+02","2015-06-10 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N6Brugernavn', '["2015-06-10 00:00:00+02","2015-06-15 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N6BrugervendtNoegle', '["2015-06-10 00:00:00+02","2015-06-15 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O7Brugertype', '["2015-06-15 00:00:00+02","2015-06-20 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N6BrugervendtNoegle', '["2015-06-15 00:00:00+02","2015-06-20 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N6Brugernavn', '["2015-06-15 00:00:00+02","2015-06-20 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N6Brugernavn', '["2015-06-20 00:00:00+02","2015-06-25 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N6BrugervendtNoegle', '["2015-06-20 00:00:00+02","2015-06-25 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O8Brugertype', '["2015-07-01 00:00:00+02","2015-07-05 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'O8BrugervendtNoegle', '["2015-07-01 00:00:00+02","2015-07-05 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N7Brugernavn', '["2015-07-05 00:00:00+02","2015-07-10 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O8Brugertype', '["2015-07-05 00:00:00+02","2015-07-10 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N7BrugervendtNoegle', '["2015-07-05 00:00:00+02","2015-07-10 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O8Brugertype', '["2015-07-10 00:00:00+02","2015-07-15 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'O8BrugervendtNoegle', '["2015-07-10 00:00:00+02","2015-07-15 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O8Brugertype', '["2015-07-15 00:00:00+02","2015-07-20 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N8Brugernavn', '["2015-07-15 00:00:00+02","2015-07-20 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N8BrugervendtNoegle', '["2015-07-15 00:00:00+02","2015-07-20 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O8Brugertype', '["2015-07-20 00:00:00+02","2015-07-25 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'O8BrugervendtNoegle', '["2015-07-20 00:00:00+02","2015-07-25 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N9Brugernavn', '["2015-08-01 00:00:00+02","2015-08-20 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O9Brugertype', '["2015-08-01 00:00:00+02","2015-08-20 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N9BrugervendtNoegle', '["2015-08-01 00:00:00+02","2015-08-20 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N10Brugernavn', '["2015-09-01 00:00:00+02","2015-09-05 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N10BrugervendtNoegle', '["2015-09-01 00:00:00+02","2015-09-05 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N10Brugernavn', '["2015-09-05 00:00:00+02","2015-09-10 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O10Brugertype', '["2015-09-05 00:00:00+02","2015-09-10 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N10BrugervendtNoegle', '["2015-09-05 00:00:00+02","2015-09-10 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O10Brugertype', '["2015-09-10 00:00:00+02","2015-09-15 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'O10BrugervendtNoegle', '["2015-09-10 00:00:00+02","2015-09-15 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N11Brugernavn', '["2015-09-15 00:00:00+02","2015-09-20 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O10Brugertype', '["2015-09-15 00:00:00+02","2015-09-20 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N11BrugervendtNoegle', '["2015-09-15 00:00:00+02","2015-09-20 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N11Brugernavn', '["2015-09-20 00:00:00+02","2015-09-25 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N11BrugervendtNoegle', '["2015-09-20 00:00:00+02","2015-09-25 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O11Brugertype', '["2015-10-01 00:00:00+02","2015-10-05 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'O11BrugervendtNoegle', '["2015-10-01 00:00:00+02","2015-10-05 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N12BrugervendtNoegle', '["2015-10-05 00:00:00+02","2015-10-10 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N12Brugernavn', '["2015-10-05 00:00:00+02","2015-10-10 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O11Brugertype', '["2015-10-05 00:00:00+02","2015-10-10 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N12Brugernavn', '["2015-10-10 00:00:00+02","2015-10-15 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N12BrugervendtNoegle', '["2015-10-10 00:00:00+02","2015-10-15 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O12Brugertype', '["2015-10-15 00:00:00+02","2015-10-20 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N12Brugernavn', '["2015-10-15 00:00:00+02","2015-10-20 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N12BrugervendtNoegle', '["2015-10-15 00:00:00+02","2015-10-20 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O12Brugertype', '["2015-10-20 00:00:00+02","2015-10-25 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'O12BrugervendtNoegle', '["2015-10-20 00:00:00+02","2015-10-25 00:00:00+02")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N13BrugervendtNoegle', '["2015-11-01 00:00:00+01","2015-11-10 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N13Brugernavn', '["2015-11-01 00:00:00+01","2015-11-10 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O13Brugertype', '["2015-11-01 00:00:00+01","2015-11-10 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('Brugernavn', 'N14Brugernavn', '["2015-11-10 00:00:00+01","2015-11-20 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('BrugervendtNoegle', 'N14BrugervendtNoegle', '["2015-11-10 00:00:00+01","2015-11-20 00:00:00+01")');
    INSERT INTO expected_attribut_results VALUES ('Brugertype', 'O14Brugertype', '["2015-11-10 00:00:00+01","2015-11-20 00:00:00+01")');

--     Get the actual results of the attribut update
    PREPARE attribut_test AS 
      SELECT af.Name, af.Value, (at.Virkning).TimePeriod FROM attributfelt af
      JOIN Attribut at ON af.AttributID = at.ID
      JOIN Attributter att ON at.AttributterID = att.ID
    WHERE att.RegistreringsID = $1;

--     Compare the expected results with the actual
    RETURN NEXT bag_eq('SELECT * FROM expected_attribut_results',
                       'EXECUTE attribut_test(' || reg.ID || ')');

--     Test Relationer

    PREPARE "rel_test" AS SELECT rf.ReferenceID FROM Reference rf
      JOIN Relation r1 ON r1.ID = rf.RelationID
      JOIN Relationer r2 ON r2.ID = r1.RelationerID
    WHERE r2.RegistreringsID = $1
          AND (r1.Virkning).TimePeriod = '[2015-01-20, infinity)' :: TSTZRANGE
          AND r2.Name = 'Adresser';
    RETURN NEXT results_eq('EXECUTE rel_test(' || reg.ID || ')',
                   newRelUUID,
                   'Relation replaced with new value');


--       Test egenskaber

--     RETURN NEXT (SELECT is (e1.Value, 'Brugernavnupdated',
--                             'New property value inserted') FROM Egenskab e1
--       JOIN Egenskaber e2 ON e1.EgenskaberID = e2.ID
--     WHERE e2.RegistreringsID = reg.ID
--           AND (e2.Virkning).TimePeriod = '[2015-01-01, 2015-01-10)'::TSTZRANGE
--           AND e1.Name = 'Brugernavn');
--
--     RETURN NEXT (SELECT is (e1.Value, 'BrugernavnAupdated',
--                             'New property value inserted 2') FROM Egenskab e1
--       JOIN Egenskaber e2 ON e1.EgenskaberID = e2.ID
--     WHERE e2.RegistreringsID = reg.ID
--           AND (e2.Virkning).TimePeriod = '[2015-01-15, 2015-02-05)'::TSTZRANGE
--           AND e1.Name = 'Brugernavn');
--
--     RETURN NEXT (SELECT is (e1.Value, 'BrugernavnA',
--                             'Old property value''s range is altered') FROM Egenskab e1
--       JOIN Egenskaber e2 ON e1.EgenskaberID = e2.ID
--     WHERE e2.RegistreringsID = reg.ID
--           AND (e2.Virkning).TimePeriod = '[2015-02-05, 2015-02-10)'::TSTZRANGE
--           AND e1.Name = 'Brugernavn');
--
--     RETURN NEXT ok ((SELECT COUNT(e1.*) = 0 FROM Egenskab e1
--                    JOIN Egenskaber e2 ON e1.EgenskaberID = e2.ID
--                  WHERE e2.RegistreringsID = reg.ID
--                        AND e1.Name = 'Brugernavn'
--                        AND e1.Value = 'Brugernavn'), 'Old property value is deleted');

--       Test tilstand

    RETURN NEXT ok((SELECT COUNT(*) = 1 FROM Tilstand
      JOIN Tilstande t ON t.ID = TilstandeID
      WHERE t.RegistreringsID = reg.ID
            AND t.Name = 'Gyldighed'
            AND (Virkning).TimePeriod = '[2014-11-01, 2014-12-20)'::TSTZRANGE
                   AND (Virkning).Notetekst = 'Note2'),
                   'New tilstand completely contains and replaces old');
    RETURN NEXT ok((SELECT COUNT(*) = 1 FROM Tilstand
      JOIN Tilstande t ON t.ID = TilstandeID
      WHERE t.RegistreringsID = reg.ID
            AND t.Name = 'Gyldighed'
            AND (Virkning).TimePeriod = '[2015-01-01, 2015-01-03)'::TSTZRANGE
                   AND (Virkning).Notetekst = 'Note'),
                   'Split old tilstand lower');
    RETURN NEXT ok((SELECT COUNT(*) = 1 FROM Tilstand
      JOIN Tilstande t ON t.ID = TilstandeID
      WHERE t.RegistreringsID = reg.ID
            AND t.Name = 'Gyldighed'
            AND (Virkning).TimePeriod = '[2015-01-03, 2015-01-05)'::TSTZRANGE
                   AND (Virkning).Notetekst = 'Note2'),
                   'New tilstand inserted in middle');
    RETURN NEXT ok((SELECT COUNT(*) = 1 FROM Tilstand
      JOIN Tilstande t ON t.ID = TilstandeID
      WHERE t.RegistreringsID = reg.ID
            AND t.Name = 'Gyldighed'
            AND (Virkning).TimePeriod = '[2015-01-05, 2015-01-10)'::TSTZRANGE
                   AND (Virkning).Notetekst = 'Note'),
                   'Split old tilstand upper');
    RETURN NEXT ok((SELECT COUNT(*) = 1 FROM Tilstand
      JOIN Tilstande t ON t.ID = TilstandeID
      WHERE t.RegistreringsID = reg.ID
            AND t.Name = 'Gyldighed'
            AND (Virkning).TimePeriod = '[2015-01-10, 2015-01-20)'::TSTZRANGE
                   AND Status = 'Inaktiv'),
                   'New tilstand replaced old tilstand with exact same range');
    RETURN NEXT ok((SELECT COUNT(*) = 1 FROM Tilstand
      JOIN Tilstande t ON t.ID = TilstandeID
      WHERE t.RegistreringsID = reg.ID
            AND t.Name = 'Gyldighed'
          AND (Virkning).TimePeriod = '[2015-01-20, 2015-01-25)'::TSTZRANGE
                   AND (Virkning).Notetekst = 'Note'),
                   'Old upper bound changed when new overlaps to the right');
    RETURN NEXT ok((SELECT COUNT(*) = 1 FROM Tilstand
    JOIN Tilstande t ON t.ID = TilstandeID
      WHERE t.RegistreringsID = reg.ID
            AND t.Name = 'Gyldighed'
          AND (Virkning).TimePeriod = '[2015-01-25, 2015-02-10)'::TSTZRANGE
                   AND (Virkning).Notetekst = 'Note2'),
                   'New tilstand inserted between two overlapping old');
    RETURN NEXT ok((SELECT COUNT(*) = 1 FROM Tilstand
    JOIN Tilstande t ON t.ID = TilstandeID
      WHERE t.RegistreringsID = reg.ID
            AND t.Name = 'Gyldighed'
          AND (Virkning).TimePeriod = '[2015-02-10, infinity)'::TSTZRANGE
                   AND (Virkning).Notetekst = 'Note'),
                   'Old lower bound changed when new overlaps to the left');
    RETURN NEXT ok((SELECT COUNT(*) = 0 FROM Tilstand
    WHERE (Virkning).TimePeriod = 'empty'),
                   'There should be no empty Virkning TimePeriods');

  END;
END;
$$ LANGUAGE plpgsql;



SELECT plan(13);

SELECT * FROM do_tap('test'::name);

-- Finish the tests and clean up.
SELECT * FROM finish();
ROLLBACK;
