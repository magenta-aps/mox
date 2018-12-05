-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/

--create custom type sans db-ids to be able to do "clean" function signatures "for the outside world".

CREATE TYPE SagFremdriftTils AS ENUM ('Opstaaet','Oplyst','Afgjort','Bestilt','Udfoert','Afsluttet',''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE SagFremdriftTilsType AS (
    virkning Virkning,
    fremdrift SagFremdriftTils
)
;



CREATE TYPE SagEgenskaberAttrType AS (
brugervendtnoegle text,
afleveret ClearableBoolean,

beskrivelse text,
hjemmel text,
kassationskode text,
offentlighedundtaget offentlighedundtagettype,
principiel ClearableBoolean,

sagsnummer text,
titel text,

 virkning Virkning
);




CREATE TYPE SagRelationKode AS ENUM  ('behandlingarkiv','afleveringsarkiv','primaerklasse','opgaveklasse','handlingsklasse','kontoklasse','sikkerhedsklasse','foelsomhedsklasse','indsatsklasse','ydelsesklasse','ejer','ansvarlig','primaerbehandler','udlaanttil','primaerpart','ydelsesmodtager','oversag','praecedens','afgiftsobjekt','ejendomsskat','andetarkiv','andrebehandlere','sekundaerpart','andresager','byggeri','fredning','journalpost');  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _as_convert_sag_relation_kode_to_txt is invoked.


CREATE TYPE SagRelationJournalPostSpecifikKode AS ENUM ('journalnotat','vedlagtdokument','tilakteretdokument');
 
CREATE TYPE JournalNotatType AS (
titel text,
notat text,
format text
);

CREATE TYPE JournalPostDokumentAttrType AS (
dokumenttitel text,
offentlighedUndtaget OffentlighedundtagetType
);


CREATE TYPE SagRelationType AS (
  relType SagRelationKode,
  virkning Virkning,
  uuid uuid,
  urn text,
  objektType text,
  indeks int,
  relTypeSpec SagRelationJournalPostSpecifikKode,
  journalNotat JournalNotatType,
  journalDokumentAttr JournalPostDokumentAttrType
)
;



CREATE TYPE SagRegistreringType AS
(
registrering RegistreringBase,
tilsFremdrift SagFremdriftTilsType[],
attrEgenskaber SagEgenskaberAttrType[],
relationer SagRelationType[]
);

CREATE TYPE SagType AS
(
  id uuid,
  registrering SagRegistreringType[]
);  


CREATE Type _SagRelationMaxIndex AS
(
  relType SagRelationKode,
  indeks int
);




