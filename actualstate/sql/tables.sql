
CREATE TABLE ItSystem (PRIMARY KEY (ID)) INHERITS (Objekt);

CREATE TABLE ItSystemRegistrering  (
  PRIMARY KEY (ID),
  FOREIGN KEY (ObjektID) REFERENCES ItSystem (ID),
  -- Exclude overlapping Registrering time periods for the same 'actor' type.
  EXCLUDE USING gist (uuid_to_text(ObjektID) WITH =,
    TimePeriod WITH &&)
) INHERITS (Registrering);


CREATE TABLE ItSystemAttributter (
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES ItSystemRegistrering (ID),
    UNIQUE (RegistreringsID, Name)
) INHERITS (Attributter);


CREATE TABLE ItSystemAttribut (
    PRIMARY KEY(ID),
    FOREIGN KEY (AttributterID) REFERENCES ItSystemAttributter (ID),
    -- Exclude overlapping Virkning time periods within the same Attributter
    EXCLUDE USING gist (AttributterID WITH =,
    composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Attribut);


CREATE TABLE ItSystemAttributFelt (
    PRIMARY KEY(ID),
    FOREIGN KEY (AttributID) REFERENCES ItSystemAttribut (ID),
    UNIQUE (AttributID, Name)
) INHERITS (AttributFelt);


CREATE TABLE ItSystemTilstande (
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES ItSystemRegistrering (ID),
    UNIQUE (RegistreringsID, Name)
) INHERITS (Tilstande);


CREATE TABLE ItSystemTilstand (
    PRIMARY KEY(ID),
    FOREIGN KEY (TilstandeID) REFERENCES ItSystemTilstande (ID),
    -- Exclude overlapping Virkning time periods within the same Tilstand
    EXCLUDE USING gist (TilstandeID WITH =,
    composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Tilstand);


CREATE TABLE ItSystemRelationer(
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES ItSystemRegistrering (ID),
    UNIQUE (RegistreringsID, Name)
) INHERITS (Relationer);
    

CREATE TABLE ItSystemRelation(
    PRIMARY KEY (ID),
    FOREIGN KEY (RelationerID) REFERENCES ItSystemRelationer(ID),
    -- Exclude overlapping Virkning time periods within the same Relation
    EXCLUDE USING gist (RelationerID WITH =,
      composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Relation);


CREATE TABLE ItSystemReference (
    PRIMARY KEY (ID),
    FOREIGN KEY (RelationID) REFERENCES ItSystemRelation(ID) ON DELETE CASCADE,
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


CREATE TABLE OrganisationFunktion (PRIMARY KEY (ID)) INHERITS (Objekt);

CREATE TABLE OrganisationFunktionRegistrering  (
  PRIMARY KEY (ID),
  FOREIGN KEY (ObjektID) REFERENCES OrganisationFunktion (ID),
  -- Exclude overlapping Registrering time periods for the same 'actor' type.
  EXCLUDE USING gist (uuid_to_text(ObjektID) WITH =,
    TimePeriod WITH &&)
) INHERITS (Registrering);


CREATE TABLE OrganisationFunktionAttributter (
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES OrganisationFunktionRegistrering (ID),
    UNIQUE (RegistreringsID, Name)
) INHERITS (Attributter);


CREATE TABLE OrganisationFunktionAttribut (
    PRIMARY KEY(ID),
    FOREIGN KEY (AttributterID) REFERENCES OrganisationFunktionAttributter (ID),
    -- Exclude overlapping Virkning time periods within the same Attributter
    EXCLUDE USING gist (AttributterID WITH =,
    composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Attribut);


CREATE TABLE OrganisationFunktionAttributFelt (
    PRIMARY KEY(ID),
    FOREIGN KEY (AttributID) REFERENCES OrganisationFunktionAttribut (ID),
    UNIQUE (AttributID, Name)
) INHERITS (AttributFelt);


CREATE TABLE OrganisationFunktionTilstande (
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES OrganisationFunktionRegistrering (ID),
    UNIQUE (RegistreringsID, Name)
) INHERITS (Tilstande);


CREATE TABLE OrganisationFunktionTilstand (
    PRIMARY KEY(ID),
    FOREIGN KEY (TilstandeID) REFERENCES OrganisationFunktionTilstande (ID),
    -- Exclude overlapping Virkning time periods within the same Tilstand
    EXCLUDE USING gist (TilstandeID WITH =,
    composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Tilstand);


CREATE TABLE OrganisationFunktionRelationer(
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES OrganisationFunktionRegistrering (ID),
    UNIQUE (RegistreringsID, Name)
) INHERITS (Relationer);
    

CREATE TABLE OrganisationFunktionRelation(
    PRIMARY KEY (ID),
    FOREIGN KEY (RelationerID) REFERENCES OrganisationFunktionRelationer(ID),
    -- Exclude overlapping Virkning time periods within the same Relation
    EXCLUDE USING gist (RelationerID WITH =,
      composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Relation);


CREATE TABLE OrganisationFunktionReference (
    PRIMARY KEY (ID),
    FOREIGN KEY (RelationID) REFERENCES OrganisationFunktionRelation(ID) ON DELETE CASCADE,
    -- No duplicates within the same relation!
    UNIQUE (ReferenceID, RelationID)
) INHERITS (Reference);


CREATE TABLE OrganisationEnhed (PRIMARY KEY (ID)) INHERITS (Objekt);

CREATE TABLE OrganisationEnhedRegistrering  (
  PRIMARY KEY (ID),
  FOREIGN KEY (ObjektID) REFERENCES OrganisationEnhed (ID),
  -- Exclude overlapping Registrering time periods for the same 'actor' type.
  EXCLUDE USING gist (uuid_to_text(ObjektID) WITH =,
    TimePeriod WITH &&)
) INHERITS (Registrering);


CREATE TABLE OrganisationEnhedAttributter (
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES OrganisationEnhedRegistrering (ID),
    UNIQUE (RegistreringsID, Name)
) INHERITS (Attributter);


CREATE TABLE OrganisationEnhedAttribut (
    PRIMARY KEY(ID),
    FOREIGN KEY (AttributterID) REFERENCES OrganisationEnhedAttributter (ID),
    -- Exclude overlapping Virkning time periods within the same Attributter
    EXCLUDE USING gist (AttributterID WITH =,
    composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Attribut);


CREATE TABLE OrganisationEnhedAttributFelt (
    PRIMARY KEY(ID),
    FOREIGN KEY (AttributID) REFERENCES OrganisationEnhedAttribut (ID),
    UNIQUE (AttributID, Name)
) INHERITS (AttributFelt);


CREATE TABLE OrganisationEnhedTilstande (
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES OrganisationEnhedRegistrering (ID),
    UNIQUE (RegistreringsID, Name)
) INHERITS (Tilstande);


CREATE TABLE OrganisationEnhedTilstand (
    PRIMARY KEY(ID),
    FOREIGN KEY (TilstandeID) REFERENCES OrganisationEnhedTilstande (ID),
    -- Exclude overlapping Virkning time periods within the same Tilstand
    EXCLUDE USING gist (TilstandeID WITH =,
    composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Tilstand);


CREATE TABLE OrganisationEnhedRelationer(
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES OrganisationEnhedRegistrering (ID),
    UNIQUE (RegistreringsID, Name)
) INHERITS (Relationer);
    

CREATE TABLE OrganisationEnhedRelation(
    PRIMARY KEY (ID),
    FOREIGN KEY (RelationerID) REFERENCES OrganisationEnhedRelationer(ID),
    -- Exclude overlapping Virkning time periods within the same Relation
    EXCLUDE USING gist (RelationerID WITH =,
      composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Relation);


CREATE TABLE OrganisationEnhedReference (
    PRIMARY KEY (ID),
    FOREIGN KEY (RelationID) REFERENCES OrganisationEnhedRelation(ID) ON DELETE CASCADE,
    -- No duplicates within the same relation!
    UNIQUE (ReferenceID, RelationID)
) INHERITS (Reference);


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

