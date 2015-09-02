-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

SELECT * FROM ACTUAL_STATE_CREATE(
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
          ARRAY[uuid_generate_v4()]
        ) :: RelationType
        ]
      ) :: RelationerType
      ]
  );
      -- Example call to update a user.
  SELECT * FROM ACTUAL_STATE_UPDATE(
      (SELECT ID FROM Bruger LIMIT 1),
      ARRAY [
        ROW (
        'Egenskab',
        ARRAY [
--             ROW (
--             ARRAY [
--               ROW ('BrugervendtNoegle', 'BrugervendtNoegleupdated'),
--               ROW ('Brugernavn', 'Brugernavnupdated'),
--               ROW ('Brugertype', 'Brugertypeupdated')
--             ] :: AttributFeltType [],
--             ROW ('[2015-01-01, 2015-01-02)' :: TSTZRANGE,
--             uuid_generate_v4(),
--             'Bruger',
--             'Note'
--             ) :: Virkning
--           ) :: AttributType,
          ROW (
          ARRAY [
            ROW ('BrugervendtNoegle', 'BrugervendtNoegleAupdated'),
            ROW ('Brugernavn', 'BrugernavnAupdated'),
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
          ARRAY[uuid_generate_v4()]
        ) :: RelationType
        ]
      ) :: RelationerType
      ]
);


SELECT ACTUAL_STATE_DELETE('Bruger', (SELECT ID FROM Bruger LIMIT 1));

SELECT ACTUAL_STATE_PASSIVE('Bruger', (SELECT ID FROM Bruger LIMIT 1));
