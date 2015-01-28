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


CREATE OR REPLACE FUNCTION ACTUAL_STATE_READ_BRUGER(
    ID UUID,
    VirkningPeriod TSTZRANGE,
    RegistreringPeriod TSTZRANGE,
    filteredAttributesRef REFCURSOR
)
  RETURNS SETOF REFCURSOR AS $$
DECLARE
  inputID UUID := ID;
  result BrugerRegistrering;
BEGIN
  -- Get the whole registrering which overlaps with the registrering (system)
  -- time period.
  SELECT * FROM BrugerRegistrering
    JOIN Bruger ON Bruger.ID = BrugerRegistrering.BrugerID
  WHERE Bruger.ID = inputID AND
        -- && operator means ranges overlap
        (BrugerRegistrering.Registrering).TimePeriod && RegistreringPeriod
    -- We only want the first result
    LIMIT 1
  INTO result;

  -- Filter the registrering by the virkning (application) time period
  OPEN filteredAttributesRef FOR SELECT * FROM brugeregenskaber
  WHERE brugeregenskaber.brugerregistreringid = result.id AND
        (brugeregenskaber.virkning).TimePeriod && VirkningPeriod;
  RETURN;
END;
$$ LANGUAGE plpgsql;
