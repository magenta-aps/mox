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
            ROW ('BrugervendtNoegle', 'BrugervendtNoegleA'),
            ROW ('Brugernavn', 'BrugernavnA'),
            ROW ('Brugertype', 'BrugertypeA')
          ] :: AttributFeltType [],
          ROW ('[2015-02-01, 2015-02-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Note'
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
            ROW (
            ARRAY [
              ROW ('BrugervendtNoegle', 'BrugervendtNoegleupdated'),
              ROW ('Brugernavn', 'Brugernavnupdated'),
              ROW ('Brugertype', 'Brugertypeupdated')
            ] :: AttributFeltType [],
            ROW ('[2014-01-01, 2014-01-02)' :: TSTZRANGE,
            uuid_generate_v4(),
            'Bruger',
            'Note'
            ) :: Virkning
          ) :: AttributType,
            ROW (
            ARRAY [
              ROW ('BrugervendtNoegle', 'BrugervendtNoegleAupdated'),
--               ROW ('Brugernavn', 'BrugernavnAupdated'),
              ROW ('Brugertype', 'BrugertypeAupdated')
            ] :: AttributFeltType [],
            ROW ('[2015-01-06, 2015-01-15)' :: TSTZRANGE,
            uuid_generate_v4(),
            'Bruger',
            'Note'
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



SELECT plan(12);

SELECT * FROM do_tap('test'::name);

-- Finish the tests and clean up.
SELECT * FROM finish();
COMMIT;
