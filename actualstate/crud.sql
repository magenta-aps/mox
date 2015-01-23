CREATE OR REPLACE FUNCTION ACTUAL_STATE_CREATE(Attributter BrugerEgenskaber,
 Tilstande BrugerTilstand)
  RETURNS
  Bruger AS $$
DECLARE
  brugerUUID uuid;
  brugerRegistreringID BIGINT;
BEGIN
    brugerUUID := uuid_generate_v4();
    INSERT INTO Bruger (ID) VALUES(brugerUUID);
    INSERT INTO BrugerRegistrering (BrugerID,
    Registrering) VALUES
      (brugerUUID, ROW(TSTZRANGE(now(), "infinity", "[]"),
                   'Opstaaet', null)) RETURNING ID as brugerRegistreringID;
    INSERT INTO BrugerEgenskaber (BrugerRegistreringID, Virkning, BrugervendtNoegle, Brugernavn, Brugertype)
      VALUES (Attributter.*);
END;
$$ LANGUAGE plpgsql;