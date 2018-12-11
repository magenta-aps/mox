-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/


CREATE OR REPLACE FUNCTION as_search_sag(
    firstResult int,--TOOD ??
    sag_uuid uuid,
    registreringObj   SagRegistreringType,
    virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
    maxResults int = 2147483647,
    anyAttrValueArr text[] = '{}'::text[],
    anyuuidArr uuid[] = '{}'::uuid[],
    anyurnArr text[] = '{}'::text[],
    auth_criteria_arr SagRegistreringType[]=null

    

) RETURNS uuid[] AS $$
DECLARE
    sag_candidates uuid[];
    sag_candidates_is_initialized boolean;
    --to_be_applyed_filter_uuids uuid[];
    attrEgenskaberTypeObj SagEgenskaberAttrType;

    
    tilsFremdriftTypeObj SagFremdriftTilsType;

    relationTypeObj SagRelationType;
    anyAttrValue text;
    anyuuid uuid;
    anyurn text;

    

    auth_filtered_uuids uuid[];

    
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

sag_candidates_is_initialized := false;

IF sag_uuid is not NULL THEN
    sag_candidates:= ARRAY[sag_uuid];
    sag_candidates_is_initialized:=true;
    IF registreringObj IS NULL THEN
    --RAISE DEBUG 'no registreringObj'
    ELSE
        sag_candidates:=array(
                SELECT DISTINCT
                b.sag_id
                FROM
                sag a
                JOIN sag_registrering b on b.sag_id=a.id
                WHERE
                		(
				(registreringObj.registrering) IS NULL 
				OR
				(
					(
						(registreringObj.registrering).timeperiod IS NULL 
						OR
						(registreringObj.registrering).timeperiod && (b.registrering).timeperiod
					)
					AND
					(
						(registreringObj.registrering).livscykluskode IS NULL 
						OR
						(registreringObj.registrering).livscykluskode = (b.registrering).livscykluskode 		
					) 
					AND
					(
						(registreringObj.registrering).brugerref IS NULL
						OR
						(registreringObj.registrering).brugerref = (b.registrering).brugerref
					)
					AND
					(
						(registreringObj.registrering).note IS NULL
						OR
						(b.registrering).note ILIKE (registreringObj.registrering).note
					)
			)
		)
		AND
		(
			(
				((b.registrering).livscykluskode <> 'Slettet'::Livscykluskode )
				AND
					(
						(registreringObj.registrering) IS NULL 
						OR
						(registreringObj.registrering).livscykluskode IS NULL 
					)
			)
			OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				(registreringObj.registrering).livscykluskode IS NOT NULL 
			)
		)
		AND
		(
			(
			  (
			  	(registreringObj.registrering) IS NULL
			  	OR
			  	(registreringObj.registrering).timeperiod IS NULL
			  )
			  AND
			  upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
			)  	
		OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				((registreringObj.registrering).timeperiod IS NOT NULL)
			)
		)
		AND
		((NOT sag_candidates_is_initialized) OR b.sag_id = ANY (sag_candidates) )

        );
    END IF;
END IF;


--RAISE DEBUG 'sag_candidates_is_initialized step 1:%',sag_candidates_is_initialized;
--RAISE DEBUG 'sag_candidates step 1:%',sag_candidates;
--/****************************//


--RAISE NOTICE 'sag_candidates_is_initialized step 2:%',sag_candidates_is_initialized;
--RAISE NOTICE 'sag_candidates step 2:%',sag_candidates;

--/****************************//
--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
    --RAISE DEBUG 'as_search_sag: skipping filtration on attrEgenskaber';
ELSE

    IF (coalesce(array_length(sag_candidates,1),0)>0 OR NOT sag_candidates_is_initialized) THEN
        
        FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
        
        LOOP
            sag_candidates:=array(
            SELECT DISTINCT
            b.sag_id
            FROM  sag_attr_egenskaber a
            JOIN sag_registrering b on a.sag_registrering_id=b.id
            
            WHERE
                (
                    (
                        attrEgenskaberTypeObj.virkning IS NULL 
                        OR
                        (
                            (
                                (
                                     (attrEgenskaberTypeObj.virkning).TimePeriod IS NULL
                                )
                                OR
                                (
                                    (attrEgenskaberTypeObj.virkning).TimePeriod && (a.virkning).TimePeriod
                                )
                            )
                            AND
                            (
                                    (attrEgenskaberTypeObj.virkning).AktoerRef IS NULL OR (attrEgenskaberTypeObj.virkning).AktoerRef=(a.virkning).AktoerRef
                            )
                            AND
                            (
                                    (attrEgenskaberTypeObj.virkning).AktoerTypeKode IS NULL OR (attrEgenskaberTypeObj.virkning).AktoerTypeKode=(a.virkning).AktoerTypeKode
                            )
                            AND
                            (
                                    (attrEgenskaberTypeObj.virkning).NoteTekst IS NULL OR  (a.virkning).NoteTekst ILIKE (attrEgenskaberTypeObj.virkning).NoteTekst  
                            )
                        )
                    )
                )
                AND
                (
                    (NOT (attrEgenskaberTypeObj.virkning IS NULL OR (attrEgenskaberTypeObj.virkning).TimePeriod IS NULL)) --we have already filtered on virkning above
                    OR
                    (
                        virkningSoeg IS NULL
                        OR
                        virkningSoeg && (a.virkning).TimePeriod
                    )
                )
                AND
                (
                    attrEgenskaberTypeObj.brugervendtnoegle IS NULL
                    OR
                    a.brugervendtnoegle ILIKE attrEgenskaberTypeObj.brugervendtnoegle --case insensitive
                )
                AND
                (
                    attrEgenskaberTypeObj.afleveret IS NULL
                    OR
                    a.afleveret = attrEgenskaberTypeObj.afleveret
                )
                AND
                (
                    attrEgenskaberTypeObj.beskrivelse IS NULL
                    OR
                    a.beskrivelse ILIKE attrEgenskaberTypeObj.beskrivelse --case insensitive
                )
                AND
                (
                    attrEgenskaberTypeObj.hjemmel IS NULL
                    OR
                    a.hjemmel ILIKE attrEgenskaberTypeObj.hjemmel --case insensitive
                )
                AND
                (
                    attrEgenskaberTypeObj.kassationskode IS NULL
                    OR
                    a.kassationskode ILIKE attrEgenskaberTypeObj.kassationskode --case insensitive
                )
                AND
                (
                    attrEgenskaberTypeObj.offentlighedundtaget IS NULL
                    OR
                        (
                            (
                                (attrEgenskaberTypeObj.offentlighedundtaget).AlternativTitel IS NULL
                                OR
                                (a.offentlighedundtaget).AlternativTitel ILIKE (attrEgenskaberTypeObj.offentlighedundtaget).AlternativTitel
                            )
                            AND
                            (
                                (attrEgenskaberTypeObj.offentlighedundtaget).Hjemmel IS NULL
                                OR
                                (a.offentlighedundtaget).Hjemmel ILIKE (attrEgenskaberTypeObj.offentlighedundtaget).Hjemmel
                            )
                        )
                )
                AND
                (
                    attrEgenskaberTypeObj.principiel IS NULL
                    OR
                    a.principiel = attrEgenskaberTypeObj.principiel
                )
                AND
                (
                    attrEgenskaberTypeObj.sagsnummer IS NULL
                    OR
                    a.sagsnummer ILIKE attrEgenskaberTypeObj.sagsnummer --case insensitive
                )
                AND
                (
                    attrEgenskaberTypeObj.titel IS NULL
                    OR
                    a.titel ILIKE attrEgenskaberTypeObj.titel --case insensitive
                )
                AND
                
                		(
				(registreringObj.registrering) IS NULL 
				OR
				(
					(
						(registreringObj.registrering).timeperiod IS NULL 
						OR
						(registreringObj.registrering).timeperiod && (b.registrering).timeperiod
					)
					AND
					(
						(registreringObj.registrering).livscykluskode IS NULL 
						OR
						(registreringObj.registrering).livscykluskode = (b.registrering).livscykluskode 		
					) 
					AND
					(
						(registreringObj.registrering).brugerref IS NULL
						OR
						(registreringObj.registrering).brugerref = (b.registrering).brugerref
					)
					AND
					(
						(registreringObj.registrering).note IS NULL
						OR
						(b.registrering).note ILIKE (registreringObj.registrering).note
					)
			)
		)
		AND
		(
			(
				((b.registrering).livscykluskode <> 'Slettet'::Livscykluskode )
				AND
					(
						(registreringObj.registrering) IS NULL 
						OR
						(registreringObj.registrering).livscykluskode IS NULL 
					)
			)
			OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				(registreringObj.registrering).livscykluskode IS NOT NULL 
			)
		)
		AND
		(
			(
			  (
			  	(registreringObj.registrering) IS NULL
			  	OR
			  	(registreringObj.registrering).timeperiod IS NULL
			  )
			  AND
			  upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
			)  	
		OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				((registreringObj.registrering).timeperiod IS NOT NULL)
			)
		)
		AND
		((NOT sag_candidates_is_initialized) OR b.sag_id = ANY (sag_candidates) )

            );


            sag_candidates_is_initialized:=true;

        END LOOP;
    END IF;
END IF;
--RAISE DEBUG 'sag_candidates_is_initialized step 3:%',sag_candidates_is_initialized;
--RAISE DEBUG 'sag_candidates step 3:%',sag_candidates;

--/**********************************************************//
--Filtration on anyAttrValueArr
--/**********************************************************//
IF coalesce(array_length(anyAttrValueArr ,1),0)>0 THEN

    FOREACH anyAttrValue IN ARRAY anyAttrValueArr
    LOOP
        sag_candidates:=array(

            SELECT DISTINCT
            b.sag_id
            
            FROM  sag_attr_egenskaber a
            JOIN sag_registrering b on a.sag_registrering_id=b.id
            
            WHERE
            (
                        a.brugervendtnoegle ILIKE anyAttrValue OR
                                
                        a.beskrivelse ILIKE anyAttrValue OR
                        a.hjemmel ILIKE anyAttrValue OR
                        a.kassationskode ILIKE anyAttrValue OR
                                    (a.offentlighedundtaget).Hjemmel ilike anyAttrValue OR (a.offentlighedundtaget).AlternativTitel ilike anyAttrValue OR
                                
                        a.sagsnummer ILIKE anyAttrValue OR
                        a.titel ILIKE anyAttrValue
                
            )
            AND
            (
                virkningSoeg IS NULL
                OR
                virkningSoeg && (a.virkning).TimePeriod
            )
            AND
            
            		(
				(registreringObj.registrering) IS NULL 
				OR
				(
					(
						(registreringObj.registrering).timeperiod IS NULL 
						OR
						(registreringObj.registrering).timeperiod && (b.registrering).timeperiod
					)
					AND
					(
						(registreringObj.registrering).livscykluskode IS NULL 
						OR
						(registreringObj.registrering).livscykluskode = (b.registrering).livscykluskode 		
					) 
					AND
					(
						(registreringObj.registrering).brugerref IS NULL
						OR
						(registreringObj.registrering).brugerref = (b.registrering).brugerref
					)
					AND
					(
						(registreringObj.registrering).note IS NULL
						OR
						(b.registrering).note ILIKE (registreringObj.registrering).note
					)
			)
		)
		AND
		(
			(
				((b.registrering).livscykluskode <> 'Slettet'::Livscykluskode )
				AND
					(
						(registreringObj.registrering) IS NULL 
						OR
						(registreringObj.registrering).livscykluskode IS NULL 
					)
			)
			OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				(registreringObj.registrering).livscykluskode IS NOT NULL 
			)
		)
		AND
		(
			(
			  (
			  	(registreringObj.registrering) IS NULL
			  	OR
			  	(registreringObj.registrering).timeperiod IS NULL
			  )
			  AND
			  upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
			)  	
		OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				((registreringObj.registrering).timeperiod IS NOT NULL)
			)
		)
		AND
		((NOT sag_candidates_is_initialized) OR b.sag_id = ANY (sag_candidates) )


        );

    sag_candidates_is_initialized:=true;

    END LOOP;

END IF;



--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Fremdrift
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsFremdrift IS NULL THEN
    --RAISE DEBUG 'as_search_sag: skipping filtration on tilsFremdrift';
ELSE
    IF (coalesce(array_length(sag_candidates,1),0)>0 OR sag_candidates_is_initialized IS FALSE ) THEN

        FOREACH tilsFremdriftTypeObj IN ARRAY registreringObj.tilsFremdrift
        LOOP
            sag_candidates:=array(
            SELECT DISTINCT
            b.sag_id
            FROM  sag_tils_fremdrift a
            JOIN sag_registrering b on a.sag_registrering_id=b.id
            WHERE
                (
                    tilsFremdriftTypeObj.virkning IS NULL
                    OR
                    (
                        (
                             (tilsFremdriftTypeObj.virkning).TimePeriod IS NULL
                            OR
                            (tilsFremdriftTypeObj.virkning).TimePeriod && (a.virkning).TimePeriod
                        )
                        AND
                        (
                                (tilsFremdriftTypeObj.virkning).AktoerRef IS NULL OR (tilsFremdriftTypeObj.virkning).AktoerRef=(a.virkning).AktoerRef
                        )
                        AND
                        (
                                (tilsFremdriftTypeObj.virkning).AktoerTypeKode IS NULL OR (tilsFremdriftTypeObj.virkning).AktoerTypeKode=(a.virkning).AktoerTypeKode
                        )
                        AND
                        (
                                (tilsFremdriftTypeObj.virkning).NoteTekst IS NULL OR (a.virkning).NoteTekst ILIKE (tilsFremdriftTypeObj.virkning).NoteTekst
                        )
                    )
                )
                AND
                (
                    (NOT ((tilsFremdriftTypeObj.virkning) IS NULL OR (tilsFremdriftTypeObj.virkning).TimePeriod IS NULL)) --we have already filtered on virkning above
                    OR
                    (
                        virkningSoeg IS NULL
                        OR
                        virkningSoeg && (a.virkning).TimePeriod
                    )
                )
                AND
                (
                    tilsFremdriftTypeObj.fremdrift IS NULL
                    OR
                    tilsFremdriftTypeObj.fremdrift = a.fremdrift
                )
                AND
                		(
				(registreringObj.registrering) IS NULL 
				OR
				(
					(
						(registreringObj.registrering).timeperiod IS NULL 
						OR
						(registreringObj.registrering).timeperiod && (b.registrering).timeperiod
					)
					AND
					(
						(registreringObj.registrering).livscykluskode IS NULL 
						OR
						(registreringObj.registrering).livscykluskode = (b.registrering).livscykluskode 		
					) 
					AND
					(
						(registreringObj.registrering).brugerref IS NULL
						OR
						(registreringObj.registrering).brugerref = (b.registrering).brugerref
					)
					AND
					(
						(registreringObj.registrering).note IS NULL
						OR
						(b.registrering).note ILIKE (registreringObj.registrering).note
					)
			)
		)
		AND
		(
			(
				((b.registrering).livscykluskode <> 'Slettet'::Livscykluskode )
				AND
					(
						(registreringObj.registrering) IS NULL 
						OR
						(registreringObj.registrering).livscykluskode IS NULL 
					)
			)
			OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				(registreringObj.registrering).livscykluskode IS NOT NULL 
			)
		)
		AND
		(
			(
			  (
			  	(registreringObj.registrering) IS NULL
			  	OR
			  	(registreringObj.registrering).timeperiod IS NULL
			  )
			  AND
			  upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
			)  	
		OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				((registreringObj.registrering).timeperiod IS NOT NULL)
			)
		)
		AND
		((NOT sag_candidates_is_initialized) OR b.sag_id = ANY (sag_candidates) )

    );


            sag_candidates_is_initialized:=true;


        END LOOP;
    END IF;
END IF;

/*
--relationer SagRelationType[]
*/


--RAISE DEBUG 'sag_candidates_is_initialized step 4:%',sag_candidates_is_initialized;
--RAISE DEBUG 'sag_candidates step 4:%',sag_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL THEN
    --RAISE DEBUG 'as_search_sag: skipping filtration on relationer';
ELSE
    IF (coalesce(array_length(sag_candidates,1),0)>0 OR NOT sag_candidates_is_initialized) AND (registreringObj).relationer IS NOT NULL THEN
        FOREACH relationTypeObj IN ARRAY registreringObj.relationer
        LOOP
            sag_candidates:=array(
            SELECT DISTINCT
            b.sag_id
            FROM  sag_relation a
            JOIN sag_registrering b on a.sag_registrering_id=b.id
            WHERE
                (
                    relationTypeObj.virkning IS NULL
                    OR
                    (
                        (
                             (relationTypeObj.virkning).TimePeriod IS NULL
                            OR
                            (relationTypeObj.virkning).TimePeriod && (a.virkning).TimePeriod
                        )
                        AND
                        (
                                (relationTypeObj.virkning).AktoerRef IS NULL OR (relationTypeObj.virkning).AktoerRef=(a.virkning).AktoerRef
                        )
                        AND
                        (
                                (relationTypeObj.virkning).AktoerTypeKode IS NULL OR (relationTypeObj.virkning).AktoerTypeKode=(a.virkning).AktoerTypeKode
                        )
                        AND
                        (
                                (relationTypeObj.virkning).NoteTekst IS NULL OR (a.virkning).NoteTekst ILIKE (relationTypeObj.virkning).NoteTekst
                        )
                    )
                )
                AND
                (
                    (NOT (relationTypeObj.virkning IS NULL OR (relationTypeObj.virkning).TimePeriod IS NULL)) --we have already filtered on virkning above
                    OR
                    (
                        virkningSoeg IS NULL
                        OR
                        virkningSoeg && (a.virkning).TimePeriod
                    )
                )
                AND
                (
                    relationTypeObj.relType IS NULL
                    OR
                    relationTypeObj.relType = a.rel_type
                )
                AND
                (
                    relationTypeObj.uuid IS NULL
                    OR
                    relationTypeObj.uuid = a.rel_maal_uuid
                )
                AND
                (
                    relationTypeObj.objektType IS NULL
                    OR
                    relationTypeObj.objektType = a.objekt_type
                )
                AND
                (
                    relationTypeObj.urn IS NULL
                    OR
                    relationTypeObj.urn = a.rel_maal_urn
                )
                
                AND
                (
                        relationTypeObj.indeks IS NULL
                        OR
                        relationTypeObj.indeks = a.rel_index
                )
                AND
                (
                        relationTypeObj.relTypeSpec IS NULL
                        OR
                        relationTypeObj.relTypeSpec = rel_type_spec
                )
                AND
                (
                        relationTypeObj.journalNotat IS NULL
                        OR
                        (
                                (
                                        (relationTypeObj.journalNotat).titel IS NULL
                                        OR
                                        (a.journal_notat).titel ILIKE (relationTypeObj.journalNotat).titel
                                )
                                AND
                                (
                                        (relationTypeObj.journalNotat).notat IS NULL
                                        OR
                                        (a.journal_notat).notat ILIKE (relationTypeObj.journalNotat).notat
                                )
                                AND
                                (
                                        (relationTypeObj.journalNotat).format IS NULL
                                        OR
                                        (a.journal_notat).format ILIKE (relationTypeObj.journalNotat).format
                                )
                        )
                )
                AND
                (
                        relationTypeObj.journalDokumentAttr IS NULL
                        OR
                        (
                                (
                                        (relationTypeObj.journalDokumentAttr).dokumenttitel IS NULL
                                        OR
                                        (a.journal_dokument_attr).dokumenttitel ILIKE (relationTypeObj.journalDokumentAttr).dokumenttitel
                                )
                                AND
                                (
                                        (relationTypeObj.journalDokumentAttr).offentlighedundtaget IS NULL
                                        OR
                                                (
                                                        (
                                                                ((relationTypeObj.journalDokumentAttr).offentlighedundtaget).AlternativTitel IS NULL
                                                                OR
                                                                ((a.journal_dokument_attr).offentlighedundtaget).AlternativTitel ILIKE ((relationTypeObj.journalDokumentAttr).offentlighedundtaget).AlternativTitel 
                                                        )
                                                        AND
                                                        (
                                                                ((relationTypeObj.journalDokumentAttr).offentlighedundtaget).Hjemmel IS NULL
                                                                OR
                                                                ((a.journal_dokument_attr).offentlighedundtaget).Hjemmel ILIKE ((relationTypeObj.journalDokumentAttr).offentlighedundtaget).Hjemmel
                                                        )
                                                )
                                )
                        )
                )
                
                
                AND
                		(
				(registreringObj.registrering) IS NULL 
				OR
				(
					(
						(registreringObj.registrering).timeperiod IS NULL 
						OR
						(registreringObj.registrering).timeperiod && (b.registrering).timeperiod
					)
					AND
					(
						(registreringObj.registrering).livscykluskode IS NULL 
						OR
						(registreringObj.registrering).livscykluskode = (b.registrering).livscykluskode 		
					) 
					AND
					(
						(registreringObj.registrering).brugerref IS NULL
						OR
						(registreringObj.registrering).brugerref = (b.registrering).brugerref
					)
					AND
					(
						(registreringObj.registrering).note IS NULL
						OR
						(b.registrering).note ILIKE (registreringObj.registrering).note
					)
			)
		)
		AND
		(
			(
				((b.registrering).livscykluskode <> 'Slettet'::Livscykluskode )
				AND
					(
						(registreringObj.registrering) IS NULL 
						OR
						(registreringObj.registrering).livscykluskode IS NULL 
					)
			)
			OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				(registreringObj.registrering).livscykluskode IS NOT NULL 
			)
		)
		AND
		(
			(
			  (
			  	(registreringObj.registrering) IS NULL
			  	OR
			  	(registreringObj.registrering).timeperiod IS NULL
			  )
			  AND
			  upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
			)  	
		OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				((registreringObj.registrering).timeperiod IS NOT NULL)
			)
		)
		AND
		((NOT sag_candidates_is_initialized) OR b.sag_id = ANY (sag_candidates) )

    );

            sag_candidates_is_initialized:=true;

        END LOOP;
    END IF;
END IF;
--/**********************//

IF coalesce(array_length(anyuuidArr ,1),0)>0 THEN

    FOREACH anyuuid IN ARRAY anyuuidArr
    LOOP
        sag_candidates:=array(
            SELECT DISTINCT
            b.sag_id
            
            FROM  sag_relation a
            JOIN sag_registrering b on a.sag_registrering_id=b.id
            WHERE
            
            anyuuid = a.rel_maal_uuid
            
            AND
            (
                virkningSoeg IS NULL
                OR
                virkningSoeg && (a.virkning).TimePeriod
            )
            
            AND
            		(
				(registreringObj.registrering) IS NULL 
				OR
				(
					(
						(registreringObj.registrering).timeperiod IS NULL 
						OR
						(registreringObj.registrering).timeperiod && (b.registrering).timeperiod
					)
					AND
					(
						(registreringObj.registrering).livscykluskode IS NULL 
						OR
						(registreringObj.registrering).livscykluskode = (b.registrering).livscykluskode 		
					) 
					AND
					(
						(registreringObj.registrering).brugerref IS NULL
						OR
						(registreringObj.registrering).brugerref = (b.registrering).brugerref
					)
					AND
					(
						(registreringObj.registrering).note IS NULL
						OR
						(b.registrering).note ILIKE (registreringObj.registrering).note
					)
			)
		)
		AND
		(
			(
				((b.registrering).livscykluskode <> 'Slettet'::Livscykluskode )
				AND
					(
						(registreringObj.registrering) IS NULL 
						OR
						(registreringObj.registrering).livscykluskode IS NULL 
					)
			)
			OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				(registreringObj.registrering).livscykluskode IS NOT NULL 
			)
		)
		AND
		(
			(
			  (
			  	(registreringObj.registrering) IS NULL
			  	OR
			  	(registreringObj.registrering).timeperiod IS NULL
			  )
			  AND
			  upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
			)  	
		OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				((registreringObj.registrering).timeperiod IS NOT NULL)
			)
		)
		AND
		((NOT sag_candidates_is_initialized) OR b.sag_id = ANY (sag_candidates) )


            );

    sag_candidates_is_initialized:=true;
    END LOOP;
END IF;

--/**********************//

IF coalesce(array_length(anyurnArr ,1),0)>0 THEN

    FOREACH anyurn IN ARRAY anyurnArr
    LOOP
        sag_candidates:=array(
            SELECT DISTINCT
            b.sag_id
            
            FROM  sag_relation a
            JOIN sag_registrering b on a.sag_registrering_id=b.id
            WHERE
            
            anyurn = a.rel_maal_urn
            
            AND
            (
                virkningSoeg IS NULL
                OR
                virkningSoeg && (a.virkning).TimePeriod
            )
            
            AND
            		(
				(registreringObj.registrering) IS NULL 
				OR
				(
					(
						(registreringObj.registrering).timeperiod IS NULL 
						OR
						(registreringObj.registrering).timeperiod && (b.registrering).timeperiod
					)
					AND
					(
						(registreringObj.registrering).livscykluskode IS NULL 
						OR
						(registreringObj.registrering).livscykluskode = (b.registrering).livscykluskode 		
					) 
					AND
					(
						(registreringObj.registrering).brugerref IS NULL
						OR
						(registreringObj.registrering).brugerref = (b.registrering).brugerref
					)
					AND
					(
						(registreringObj.registrering).note IS NULL
						OR
						(b.registrering).note ILIKE (registreringObj.registrering).note
					)
			)
		)
		AND
		(
			(
				((b.registrering).livscykluskode <> 'Slettet'::Livscykluskode )
				AND
					(
						(registreringObj.registrering) IS NULL 
						OR
						(registreringObj.registrering).livscykluskode IS NULL 
					)
			)
			OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				(registreringObj.registrering).livscykluskode IS NOT NULL 
			)
		)
		AND
		(
			(
			  (
			  	(registreringObj.registrering) IS NULL
			  	OR
			  	(registreringObj.registrering).timeperiod IS NULL
			  )
			  AND
			  upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
			)  	
		OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				((registreringObj.registrering).timeperiod IS NOT NULL)
			)
		)
		AND
		((NOT sag_candidates_is_initialized) OR b.sag_id = ANY (sag_candidates) )


            );

    sag_candidates_is_initialized:=true;
    END LOOP;
END IF;

--/**********************//

 




--RAISE DEBUG 'sag_candidates_is_initialized step 5:%',sag_candidates_is_initialized;
--RAISE DEBUG 'sag_candidates step 5:%',sag_candidates;

IF registreringObj IS NULL THEN
    --RAISE DEBUG 'registreringObj IS NULL';
ELSE
    IF NOT sag_candidates_is_initialized THEN
        sag_candidates:=array(
        SELECT DISTINCT
            sag_id
        FROM
            sag_registrering b
        WHERE
        		(
				(registreringObj.registrering) IS NULL 
				OR
				(
					(
						(registreringObj.registrering).timeperiod IS NULL 
						OR
						(registreringObj.registrering).timeperiod && (b.registrering).timeperiod
					)
					AND
					(
						(registreringObj.registrering).livscykluskode IS NULL 
						OR
						(registreringObj.registrering).livscykluskode = (b.registrering).livscykluskode 		
					) 
					AND
					(
						(registreringObj.registrering).brugerref IS NULL
						OR
						(registreringObj.registrering).brugerref = (b.registrering).brugerref
					)
					AND
					(
						(registreringObj.registrering).note IS NULL
						OR
						(b.registrering).note ILIKE (registreringObj.registrering).note
					)
			)
		)
		AND
		(
			(
				((b.registrering).livscykluskode <> 'Slettet'::Livscykluskode )
				AND
					(
						(registreringObj.registrering) IS NULL 
						OR
						(registreringObj.registrering).livscykluskode IS NULL 
					)
			)
			OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				(registreringObj.registrering).livscykluskode IS NOT NULL 
			)
		)
		AND
		(
			(
			  (
			  	(registreringObj.registrering) IS NULL
			  	OR
			  	(registreringObj.registrering).timeperiod IS NULL
			  )
			  AND
			  upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
			)  	
		OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				((registreringObj.registrering).timeperiod IS NOT NULL)
			)
		)
		AND
		((NOT sag_candidates_is_initialized) OR b.sag_id = ANY (sag_candidates) )

        )
        ;

        sag_candidates_is_initialized:=true;
    END IF;
END IF;


IF NOT sag_candidates_is_initialized THEN
    --No filters applied!
    sag_candidates:=array(
        SELECT DISTINCT id FROM sag a
    );
ELSE
    sag_candidates:=array(
        SELECT DISTINCT id FROM unnest(sag_candidates) as a(id)
        );
END IF;

--RAISE DEBUG 'sag_candidates_is_initialized step 6:%',sag_candidates_is_initialized;
--RAISE DEBUG 'sag_candidates step 6:%',sag_candidates;


/*** Filter out the objects that does not meets the stipulated access criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_sag(sag_candidates,auth_criteria_arr); 
/*********************/
IF firstResult > 0 or maxResults < 2147483647 THEN
   auth_filtered_uuids = _as_sorted_sag(auth_filtered_uuids, virkningSoeg, registreringObj, firstResult, maxResults);
END IF;
return auth_filtered_uuids;


END;
$$ LANGUAGE plpgsql STABLE; 




