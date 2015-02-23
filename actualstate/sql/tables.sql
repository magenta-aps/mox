-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

CREATE TABLE Interessefaellesskab (PRIMARY KEY (ID)) INHERITS (Objekt);

CREATE TABLE InteressefaellesskabRegistrering  (
  PRIMARY KEY (ID),
  FOREIGN KEY (ObjektID) REFERENCES Interessefaellesskab (ID),
  -- Exclude overlapping Registrering time periods for the same 'actor' type.
  EXCLUDE USING gist (uuid_to_text(ObjektID) WITH =,
    TimePeriod WITH &&)
) INHERITS (Registrering);


CREATE TABLE InteressefaellesskabAttributter (
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES InteressefaellesskabRegistrering (ID),
    UNIQUE (RegistreringsID, Name)
) INHERITS (Attributter);


CREATE TABLE InteressefaellesskabAttribut (
    PRIMARY KEY(ID),
    FOREIGN KEY (AttributterID) REFERENCES InteressefaellesskabAttributter (ID),
    -- Exclude overlapping Virkning time periods within the same Attributter
    EXCLUDE USING gist (AttributterID WITH =,
    composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Attribut);


CREATE TABLE InteressefaellesskabAttributFelt (
    PRIMARY KEY(ID),
    FOREIGN KEY (AttributID) REFERENCES InteressefaellesskabAttribut (ID),
    UNIQUE (AttributID, Name)
) INHERITS (AttributFelt);


CREATE TABLE InteressefaellesskabTilstande (
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES InteressefaellesskabRegistrering (ID),
    UNIQUE (RegistreringsID, Name)
) INHERITS (Tilstande);


CREATE TABLE InteressefaellesskabTilstand (
    PRIMARY KEY(ID),
    FOREIGN KEY (TilstandeID) REFERENCES InteressefaellesskabTilstande (ID),
    -- Exclude overlapping Virkning time periods within the same Tilstand
    EXCLUDE USING gist (TilstandeID WITH =,
    composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Tilstand);


CREATE TABLE InteressefaellesskabRelationer(
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES InteressefaellesskabRegistrering (ID),
    UNIQUE (RegistreringsID, Name)
) INHERITS (Relationer);
    

CREATE TABLE InteressefaellesskabRelation(
    PRIMARY KEY (ID),
    FOREIGN KEY (RelationerID) REFERENCES InteressefaellesskabRelationer(ID),
    -- Exclude overlapping Virkning time periods within the same Relation
    EXCLUDE USING gist (RelationerID WITH =,
      composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Relation);


CREATE TABLE InteressefaellesskabReference (
    PRIMARY KEY (ID),
    FOREIGN KEY (RelationID) REFERENCES InteressefaellesskabRelation(ID) ON DELETE CASCADE,
    -- No duplicates within the same relation!
    UNIQUE (ReferenceID, RelationID)
) INHERITS (Reference);


CREATE TABLE Organisation (PRIMARY KEY (ID)) INHERITS (Objekt);

CREATE TABLE OrganisationRegistrering  (
  PRIMARY KEY (ID),
  FOREIGN KEY (ObjektID) REFERENCES Organisation (ID),
  -- Exclude overlapping Registrering time periods for the same 'actor' type.
  EXCLUDE USING gist (uuid_to_text(ObjektID) WITH =,
    TimePeriod WITH &&)
) INHERITS (Registrering);


CREATE TABLE OrganisationAttributter (
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES OrganisationRegistrering (ID),
    UNIQUE (RegistreringsID, Name)
) INHERITS (Attributter);


CREATE TABLE OrganisationAttribut (
    PRIMARY KEY(ID),
    FOREIGN KEY (AttributterID) REFERENCES OrganisationAttributter (ID),
    -- Exclude overlapping Virkning time periods within the same Attributter
    EXCLUDE USING gist (AttributterID WITH =,
    composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Attribut);


CREATE TABLE OrganisationAttributFelt (
    PRIMARY KEY(ID),
    FOREIGN KEY (AttributID) REFERENCES OrganisationAttribut (ID),
    UNIQUE (AttributID, Name)
) INHERITS (AttributFelt);


CREATE TABLE OrganisationTilstande (
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES OrganisationRegistrering (ID),
    UNIQUE (RegistreringsID, Name)
) INHERITS (Tilstande);


CREATE TABLE OrganisationTilstand (
    PRIMARY KEY(ID),
    FOREIGN KEY (TilstandeID) REFERENCES OrganisationTilstande (ID),
    -- Exclude overlapping Virkning time periods within the same Tilstand
    EXCLUDE USING gist (TilstandeID WITH =,
    composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Tilstand);


CREATE TABLE OrganisationRelationer(
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES OrganisationRegistrering (ID),
    UNIQUE (RegistreringsID, Name)
) INHERITS (Relationer);
    

CREATE TABLE OrganisationRelation(
    PRIMARY KEY (ID),
    FOREIGN KEY (RelationerID) REFERENCES OrganisationRelationer(ID),
    -- Exclude overlapping Virkning time periods within the same Relation
    EXCLUDE USING gist (RelationerID WITH =,
      composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Relation);


CREATE TABLE OrganisationReference (
    PRIMARY KEY (ID),
    FOREIGN KEY (RelationID) REFERENCES OrganisationRelation(ID) ON DELETE CASCADE,
    -- No duplicates within the same relation!
    UNIQUE (ReferenceID, RelationID)
) INHERITS (Reference);


CREATE TABLE Bruger (PRIMARY KEY (ID)) INHERITS (Objekt);

CREATE TABLE BrugerRegistrering  (
  PRIMARY KEY (ID),
  FOREIGN KEY (ObjektID) REFERENCES Bruger (ID),
  -- Exclude overlapping Registrering time periods for the same 'actor' type.
  EXCLUDE USING gist (uuid_to_text(ObjektID) WITH =,
    TimePeriod WITH &&)
) INHERITS (Registrering);


CREATE TABLE BrugerAttributter (
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES BrugerRegistrering (ID),
    UNIQUE (RegistreringsID, Name)
) INHERITS (Attributter);


CREATE TABLE BrugerAttribut (
    PRIMARY KEY(ID),
    FOREIGN KEY (AttributterID) REFERENCES BrugerAttributter (ID),
    -- Exclude overlapping Virkning time periods within the same Attributter
    EXCLUDE USING gist (AttributterID WITH =,
    composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Attribut);


CREATE TABLE BrugerAttributFelt (
    PRIMARY KEY(ID),
    FOREIGN KEY (AttributID) REFERENCES BrugerAttribut (ID),
    UNIQUE (AttributID, Name)
) INHERITS (AttributFelt);


CREATE TABLE BrugerTilstande (
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES BrugerRegistrering (ID),
    UNIQUE (RegistreringsID, Name)
) INHERITS (Tilstande);


CREATE TABLE BrugerTilstand (
    PRIMARY KEY(ID),
    FOREIGN KEY (TilstandeID) REFERENCES BrugerTilstande (ID),
    -- Exclude overlapping Virkning time periods within the same Tilstand
    EXCLUDE USING gist (TilstandeID WITH =,
    composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Tilstand);


CREATE TABLE BrugerRelationer(
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES BrugerRegistrering (ID),
    UNIQUE (RegistreringsID, Name)
) INHERITS (Relationer);
    

CREATE TABLE BrugerRelation(
    PRIMARY KEY (ID),
    FOREIGN KEY (RelationerID) REFERENCES BrugerRelationer(ID),
    -- Exclude overlapping Virkning time periods within the same Relation
    EXCLUDE USING gist (RelationerID WITH =,
      composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Relation);


CREATE TABLE BrugerReference (
    PRIMARY KEY (ID),
    FOREIGN KEY (RelationID) REFERENCES BrugerRelation(ID) ON DELETE CASCADE,
    -- No duplicates within the same relation!
    UNIQUE (ReferenceID, RelationID)
) INHERITS (Reference);

