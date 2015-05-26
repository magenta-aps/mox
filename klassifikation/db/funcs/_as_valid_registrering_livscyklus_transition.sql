
-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.


CREATE OR REPLACE FUNCTION _as_valid_registrering_livscyklus_transition (
  current_reg_livscykluskode Livscykluskode, 
  new_reg_livscykluskode Livscykluskode)
RETURNS
boolean

AS 
$$
DECLARE 
IMPORTERET Livscykluskode := 'Importeret'::Livscykluskode ;
OPSTAAET Livscykluskode := 'Opstaaet'::Livscykluskode ;
PASSIVERET Livscykluskode := 'Passiveret'::Livscykluskode ;
SLETTET Livscykluskode := 'Slettet'::Livscykluskode ;
RETTET Livscykluskode := 'Rettet' ::Livscykluskode ;
BEGIN

CASE current_reg_livscykluskode
	WHEN OPSTAAET THEN
		CASE new_reg_livscykluskode
			WHEN IMPORTERET THEN return false;
			WHEN OPSTAAET THEN return true;
			WHEN PASSIVERET THEN return true;
			WHEN SLETTET THEN return true;
			WHEN RETTET THEN return true;
		END CASE;
	WHEN IMPORTERET THEN
		CASE new_reg_livscykluskode
			WHEN IMPORTERET THEN return true;
			WHEN OPSTAAET THEN return false;
			WHEN PASSIVERET  THEN return true;
			WHEN SLETTET THEN return true;
			WHEN RETTET THEN return true;
		END CASE;
	WHEN PASSIVERET THEN
		CASE new_reg_livscykluskode
			WHEN IMPORTERET THEN return true;
			WHEN OPSTAAET THEN return false;
			WHEN PASSIVERET  THEN return true;
			WHEN SLETTET THEN return true;
			WHEN RETTET THEN return true; --TODO Verify
		END CASE;
	WHEN SLETTET THEN return false; 
	WHEN RETTET THEN
		CASE new_reg_livscykluskode
			WHEN IMPORTERET THEN return false;
			WHEN OPSTAAET THEN return false;
			WHEN PASSIVERET  THEN return true;
			WHEN SLETTET THEN return true;
			WHEN RETTET THEN return true; 
		END CASE;

END CASE
;

RAISE EXCEPTION 'Undefined livscykluskode-transition, from [%] to [%] ',current_reg_livscykluskode,new_reg_livscykluskode;


END;
$$ LANGUAGE plpgsql IMMUTABLE;