-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

CREATE TYPE AktoerTypeKode AS ENUM (
  'Organisation',
  'OrganisationEnhed',
  'OrganisationFunktion',
  'Bruger',
  'ItSystem',
  'Interessefaellesskab'
);

CREATE TYPE Virkning AS (
  TimePeriod TSTZRANGE,
  AktoerRef UUID,
  AktoerTypeKode AktoerTypeKode,
  NoteTekst TEXT
);

CREATE TYPE LivscyklusKode AS ENUM (
  'Opstaaet',
  'Importeret',
  'Passiveret',
  'Slettet',
  'Rettet'
);

CREATE TYPE RegistreringBase AS --should be renamed to Registrering, when the old 'Registrering'-type is replaced
(
timeperiod tstzrange,
livscykluskode livscykluskode,
brugerref uuid,
note text
);

CREATE TYPE OffentlighedundtagetType AS 
(
AlternativTitel text,
Hjemmel text
);
