CREATE OR REPLACE FUNCTION ACTUAL_STATE_CREATE_BRUGER(
    Attributter BrugerEgenskaberType[],
    Tilstande BrugerTilstandType[]
)
  RETURNS Bruger AS $$
DECLARE
  brugerUUID uuid;
  brugerRegistreringID BIGINT;
  result Bruger;
BEGIN
    brugerUUID := uuid_generate_v4();
--   Create Bruger
    INSERT INTO Bruger (ID) VALUES(brugerUUID);
--   Create Registrering starting from now until infinity
--   TODO: Insert Note into registrering?
    INSERT INTO BrugerRegistrering (BrugerID, Registrering) VALUES
      (brugerUUID, ROW(TSTZRANGE(now(), 'infinity', '[]'),
                   'Opstaaet', null)) RETURNING ID INTO brugerRegistreringID;
--   Loop through attributes and add them to the registration
  DECLARE
    attr BrugerEgenskaberType;
  BEGIN
  FOREACH attr in ARRAY Attributter
    LOOP
      INSERT INTO BrugerEgenskaber (BrugerRegistreringID, Virkning, BrugervendtNoegle, Brugernavn, Brugertype)
    VALUES (brugerRegistreringID, attr.Virkning, attr.BrugervendtNoegle,
            attr.Brugernavn, attr.Brugertype);
    END LOOP;
  END;

--   Loop through states and add them to the registration
  DECLARE
    state BrugerTilstandType;
  BEGIN
    FOREACH state in ARRAY Tilstande
    LOOP
      INSERT INTO BrugerTilstand (BrugerRegistreringID, Virkning, Status)
      VALUES (brugerRegistreringID, state.Virkning, state.Status);
    END LOOP;
  END;

  SELECT * FROM Bruger WHERE ID = brugerUUID INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Example call to create a user
SELECT ACTUAL_STATE_CREATE_BRUGER(
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
);