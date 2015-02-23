-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

CREATE OR REPLACE FUNCTION ACTUAL_STATE_BRUGER_SEARCH(
    SearchId UUID = null,
    FraTil TSTZRANGE = null,
    Atributter EgenskaberType = null
)
    -- This function is going to take A LOT of parameters!
    -- i.e., more to come
    RETURNS SETOF UUID as $$
    DECLARE 
        result UUID;

    BEGIN
        RETURN QUERY
        SELECT DISTINCT b.id FROM Bruger b, BrugerRegistrering BR,
        BrugerEgenskaber E
        WHERE 
        -- Join conditions
        BR.objektid = B.id AND E.registreringsid = BR.id
        -- Search conditions
        AND (SearchId is null OR B.ID = SearchId) 
        AND (FraTil is null OR FraTil && BR.timeperiod)
        AND (Atributter.BrugervendtNoegle  is null or
                Atributter.BrugervendtNoegle = E.brugervendtnoegle 
            )
        AND (Atributter.Virkning is null OR  
            (Atributter.Virkning).timeperiod && (E.virkning).timeperiod
        )
        AND ((select ARRAY(select unnest((Atributter).Properties))) <@
              (select ARRAY(select distinct (name, value)::EgenskabsType
                    FROM egenskab WHERE 
                egenskaberid = E.id))
        );


    END;
    $$ LANGUAGE plpgsql;
