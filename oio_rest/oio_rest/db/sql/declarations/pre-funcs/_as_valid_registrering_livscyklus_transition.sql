-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

CREATE OR REPLACE FUNCTION _as_valid_registrering_livscyklus_transition (current_reg_livscykluskode Livscykluskode, new_reg_livscykluskode Livscykluskode)
    RETURNS boolean
    AS $$
DECLARE
    IMPORTERET Livscykluskode := 'Importeret'::Livscykluskode;
    OPSTAAET Livscykluskode := 'Opstaaet'::Livscykluskode;
    PASSIVERET Livscykluskode := 'Passiveret'::Livscykluskode;
    SLETTET Livscykluskode := 'Slettet'::Livscykluskode;
    RETTET Livscykluskode := 'Rettet'::Livscykluskode;
BEGIN
    CASE current_reg_livscykluskode
    WHEN OPSTAAET THEN
        CASE new_reg_livscykluskode
        WHEN IMPORTERET THEN
            RETURN FALSE;
    WHEN OPSTAAET THEN
        RETURN FALSE;
    WHEN PASSIVERET THEN
        RETURN TRUE;
    WHEN SLETTET THEN
        RETURN TRUE;
    WHEN RETTET THEN
        RETURN TRUE;
    END CASE;
    WHEN IMPORTERET THEN
        CASE new_reg_livscykluskode
        WHEN IMPORTERET THEN
            RETURN FALSE;
    WHEN OPSTAAET THEN
        RETURN FALSE;
    WHEN PASSIVERET THEN
        RETURN TRUE;
    WHEN SLETTET THEN
        RETURN TRUE;
    WHEN RETTET THEN
        RETURN TRUE;
    END CASE;
    WHEN PASSIVERET THEN
        CASE new_reg_livscykluskode
        WHEN IMPORTERET THEN
            RETURN TRUE;
    WHEN OPSTAAET THEN
        RETURN FALSE;
    WHEN PASSIVERET THEN
        RETURN FALSE;
    WHEN SLETTET THEN
        RETURN TRUE;
    WHEN RETTET THEN
        RETURN FALSE;
    END CASE;
    WHEN SLETTET THEN
        CASE new_reg_livscykluskode
        WHEN IMPORTERET THEN
            RETURN TRUE;
    WHEN OPSTAAET THEN
        RETURN FALSE;
    WHEN PASSIVERET THEN
        RETURN FALSE;
    WHEN SLETTET THEN
        RETURN FALSE;
    WHEN RETTET THEN
        RETURN FALSE;
    END CASE;
    WHEN RETTET THEN
        CASE new_reg_livscykluskode
        WHEN IMPORTERET THEN
            RETURN FALSE;
    WHEN OPSTAAET THEN
        RETURN FALSE;
    WHEN PASSIVERET THEN
        RETURN TRUE;
    WHEN SLETTET THEN
        RETURN TRUE;
    WHEN RETTET THEN
        RETURN TRUE;
    END CASE;
    END CASE;
    RAISE
    EXCEPTION 'Undefined livscykluskode-transition, from [%] to [%] ', current_reg_livscykluskode, new_reg_livscykluskode;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
