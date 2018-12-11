-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/


CREATE OR REPLACE FUNCTION as_search_klasse(
    firstResult int,--TOOD ??
    klasse_uuid uuid,
    registreringObj   KlasseRegistreringType,
    virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
    maxResults int = 2147483647,
    anyAttrValueArr text[] = '{}'::text[],
    anyuuidArr uuid[] = '{}'::uuid[],
    anyurnArr text[] = '{}'::text[],
    auth_criteria_arr KlasseRegistreringType[]=null

    

) RETURNS uuid[] AS $$
DECLARE
    klasse_candidates uuid[];
    klasse_candidates_is_initialized boolean;
    --to_be_applyed_filter_uuids uuid[];
    attrEgenskaberTypeObj KlasseEgenskaberAttrType;

    
    tilsPubliceretTypeObj KlassePubliceretTilsType;

    relationTypeObj KlasseRelationType;
    anyAttrValue text;
    anyuuid uuid;
    anyurn text;

    

    auth_filtered_uuids uuid[];

    
    manipulatedAttrEgenskaberArr KlasseEgenskaberAttrType[]:='{}';
    soegeordObj KlasseSoegeordType;
    
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

klasse_candidates_is_initialized := false;

IF klasse_uuid is not NULL THEN
    klasse_candidates:= ARRAY[klasse_uuid];
    klasse_candidates_is_initialized:=true;
    IF registreringObj IS NULL THEN
    --RAISE DEBUG 'no registreringObj'
    ELSE
        klasse_candidates:=array(
                SELECT DISTINCT
                b.klasse_id
                FROM
                klasse a
                JOIN klasse_registrering b on b.klasse_id=a.id
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
		((NOT klasse_candidates_is_initialized) OR b.klasse_id = ANY (klasse_candidates) )

        );
    END IF;
END IF;


--RAISE DEBUG 'klasse_candidates_is_initialized step 1:%',klasse_candidates_is_initialized;
--RAISE DEBUG 'klasse_candidates step 1:%',klasse_candidates;
--/****************************//


--RAISE NOTICE 'klasse_candidates_is_initialized step 2:%',klasse_candidates_is_initialized;
--RAISE NOTICE 'klasse_candidates step 2:%',klasse_candidates;

--/****************************//
--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
    --RAISE DEBUG 'as_search_klasse: skipping filtration on attrEgenskaber';
ELSE


--To help facilitate the comparrison efforts (while diverging at a minimum form the templated db-kode,
--we'll manipulate the attrEgenskaber array so to make sure that every object only has 1 sogeord element - duplicating the parent elements in attrEgenskaber as needed  )

FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
LOOP
       IF  (attrEgenskaberTypeObj).soegeord IS NULL OR coalesce(array_length((attrEgenskaberTypeObj).soegeord,1),0)<2 THEN
       manipulatedAttrEgenskaberArr:=array_append(manipulatedAttrEgenskaberArr,attrEgenskaberTypeObj); --The element only has 0 or 1 soegeord element, så no manipulations is needed.
       ELSE
               FOREACH soegeordObj IN ARRAY (attrEgenskaberTypeObj).soegeord
               LOOP
                       manipulatedAttrEgenskaberArr:=array_append(manipulatedAttrEgenskaberArr,
                               ROW (
                                       attrEgenskaberTypeObj.brugervendtnoegle,
                                       attrEgenskaberTypeObj.beskrivelse,
                                       attrEgenskaberTypeObj.eksempel,
                                       attrEgenskaberTypeObj.omfang,
                                       attrEgenskaberTypeObj.titel,
                                       attrEgenskaberTypeObj.retskilde,
                                       attrEgenskaberTypeObj.aendringsnotat,
                                       ARRAY[soegeordObj]::KlasseSoegeordType[], --NOTICE: Only 1 element in array
                                       attrEgenskaberTypeObj.virkning
                                       )::KlasseEgenskaberAttrType
                               );
               END LOOP;
       END IF;
END LOOP;

    IF (coalesce(array_length(klasse_candidates,1),0)>0 OR NOT klasse_candidates_is_initialized) THEN
        
        FOREACH attrEgenskaberTypeObj IN ARRAY manipulatedAttrEgenskaberArr
        
        LOOP
            klasse_candidates:=array(
            SELECT DISTINCT
            b.klasse_id
            FROM  klasse_attr_egenskaber a
            JOIN klasse_registrering b on a.klasse_registrering_id=b.id
            
            LEFT JOIN klasse_attr_egenskaber_soegeord c on a.id=c.klasse_attr_egenskaber_id
            
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
                    attrEgenskaberTypeObj.beskrivelse IS NULL
                    OR
                    a.beskrivelse ILIKE attrEgenskaberTypeObj.beskrivelse --case insensitive
                )
                AND
                (
                    attrEgenskaberTypeObj.eksempel IS NULL
                    OR
                    a.eksempel ILIKE attrEgenskaberTypeObj.eksempel --case insensitive
                )
                AND
                (
                    attrEgenskaberTypeObj.omfang IS NULL
                    OR
                    a.omfang ILIKE attrEgenskaberTypeObj.omfang --case insensitive
                )
                AND
                (
                    attrEgenskaberTypeObj.titel IS NULL
                    OR
                    a.titel ILIKE attrEgenskaberTypeObj.titel --case insensitive
                )
                AND
                (
                    attrEgenskaberTypeObj.retskilde IS NULL
                    OR
                    a.retskilde ILIKE attrEgenskaberTypeObj.retskilde --case insensitive
                )
                AND
                (
                    attrEgenskaberTypeObj.aendringsnotat IS NULL
                    OR
                    a.aendringsnotat ILIKE attrEgenskaberTypeObj.aendringsnotat --case insensitive
                )
                AND
                
                (
                        (attrEgenskaberTypeObj.soegeord IS NULL OR array_length(attrEgenskaberTypeObj.soegeord,1)=0)
                        OR
                        (
                                (
                                        (attrEgenskaberTypeObj.soegeord[1]).soegeordidentifikator IS NULL
                                        OR
                                        c.soegeordidentifikator ILIKE (attrEgenskaberTypeObj.soegeord[1]).soegeordidentifikator  
                                )
                                AND
                                (
                                        (attrEgenskaberTypeObj.soegeord[1]).beskrivelse IS NULL
                                        OR
                                        c.beskrivelse ILIKE (attrEgenskaberTypeObj.soegeord[1]).beskrivelse  
                                )               
                                AND
                                (
                                        (attrEgenskaberTypeObj.soegeord[1]).soegeordskategori IS NULL
                                        OR
                                        c.soegeordskategori ILIKE (attrEgenskaberTypeObj.soegeord[1]).soegeordskategori  
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
		((NOT klasse_candidates_is_initialized) OR b.klasse_id = ANY (klasse_candidates) )

            );


            klasse_candidates_is_initialized:=true;

        END LOOP;
    END IF;
END IF;
--RAISE DEBUG 'klasse_candidates_is_initialized step 3:%',klasse_candidates_is_initialized;
--RAISE DEBUG 'klasse_candidates step 3:%',klasse_candidates;

--/**********************************************************//
--Filtration on anyAttrValueArr
--/**********************************************************//
IF coalesce(array_length(anyAttrValueArr ,1),0)>0 THEN

    FOREACH anyAttrValue IN ARRAY anyAttrValueArr
    LOOP
        klasse_candidates:=array(

            SELECT DISTINCT
            b.klasse_id
            
            FROM  klasse_attr_egenskaber a
            JOIN klasse_registrering b on a.klasse_registrering_id=b.id
            
            LEFT JOIN klasse_attr_egenskaber_soegeord c on a.id=c.klasse_attr_egenskaber_id
            
            WHERE
            (
                        a.brugervendtnoegle ILIKE anyAttrValue OR
                        a.beskrivelse ILIKE anyAttrValue OR
                        a.eksempel ILIKE anyAttrValue OR
                        a.omfang ILIKE anyAttrValue OR
                        a.titel ILIKE anyAttrValue OR
                        a.retskilde ILIKE anyAttrValue OR
                        a.aendringsnotat ILIKE anyAttrValue
                
                OR
                c.soegeordidentifikator ILIKE anyAttrValue
                OR
                c.beskrivelse ILIKE anyAttrValue
                OR
                c.soegeordskategori ILIKE anyAttrValue
                
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
		((NOT klasse_candidates_is_initialized) OR b.klasse_id = ANY (klasse_candidates) )


        );

    klasse_candidates_is_initialized:=true;

    END LOOP;

END IF;



--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Publiceret
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsPubliceret IS NULL THEN
    --RAISE DEBUG 'as_search_klasse: skipping filtration on tilsPubliceret';
ELSE
    IF (coalesce(array_length(klasse_candidates,1),0)>0 OR klasse_candidates_is_initialized IS FALSE ) THEN

        FOREACH tilsPubliceretTypeObj IN ARRAY registreringObj.tilsPubliceret
        LOOP
            klasse_candidates:=array(
            SELECT DISTINCT
            b.klasse_id
            FROM  klasse_tils_publiceret a
            JOIN klasse_registrering b on a.klasse_registrering_id=b.id
            WHERE
                (
                    tilsPubliceretTypeObj.virkning IS NULL
                    OR
                    (
                        (
                             (tilsPubliceretTypeObj.virkning).TimePeriod IS NULL
                            OR
                            (tilsPubliceretTypeObj.virkning).TimePeriod && (a.virkning).TimePeriod
                        )
                        AND
                        (
                                (tilsPubliceretTypeObj.virkning).AktoerRef IS NULL OR (tilsPubliceretTypeObj.virkning).AktoerRef=(a.virkning).AktoerRef
                        )
                        AND
                        (
                                (tilsPubliceretTypeObj.virkning).AktoerTypeKode IS NULL OR (tilsPubliceretTypeObj.virkning).AktoerTypeKode=(a.virkning).AktoerTypeKode
                        )
                        AND
                        (
                                (tilsPubliceretTypeObj.virkning).NoteTekst IS NULL OR (a.virkning).NoteTekst ILIKE (tilsPubliceretTypeObj.virkning).NoteTekst
                        )
                    )
                )
                AND
                (
                    (NOT ((tilsPubliceretTypeObj.virkning) IS NULL OR (tilsPubliceretTypeObj.virkning).TimePeriod IS NULL)) --we have already filtered on virkning above
                    OR
                    (
                        virkningSoeg IS NULL
                        OR
                        virkningSoeg && (a.virkning).TimePeriod
                    )
                )
                AND
                (
                    tilsPubliceretTypeObj.publiceret IS NULL
                    OR
                    tilsPubliceretTypeObj.publiceret = a.publiceret
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
		((NOT klasse_candidates_is_initialized) OR b.klasse_id = ANY (klasse_candidates) )

    );


            klasse_candidates_is_initialized:=true;


        END LOOP;
    END IF;
END IF;

/*
--relationer KlasseRelationType[]
*/


--RAISE DEBUG 'klasse_candidates_is_initialized step 4:%',klasse_candidates_is_initialized;
--RAISE DEBUG 'klasse_candidates step 4:%',klasse_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL THEN
    --RAISE DEBUG 'as_search_klasse: skipping filtration on relationer';
ELSE
    IF (coalesce(array_length(klasse_candidates,1),0)>0 OR NOT klasse_candidates_is_initialized) AND (registreringObj).relationer IS NOT NULL THEN
        FOREACH relationTypeObj IN ARRAY registreringObj.relationer
        LOOP
            klasse_candidates:=array(
            SELECT DISTINCT
            b.klasse_id
            FROM  klasse_relation a
            JOIN klasse_registrering b on a.klasse_registrering_id=b.id
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
		((NOT klasse_candidates_is_initialized) OR b.klasse_id = ANY (klasse_candidates) )

    );

            klasse_candidates_is_initialized:=true;

        END LOOP;
    END IF;
END IF;
--/**********************//

IF coalesce(array_length(anyuuidArr ,1),0)>0 THEN

    FOREACH anyuuid IN ARRAY anyuuidArr
    LOOP
        klasse_candidates:=array(
            SELECT DISTINCT
            b.klasse_id
            
            FROM  klasse_relation a
            JOIN klasse_registrering b on a.klasse_registrering_id=b.id
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
		((NOT klasse_candidates_is_initialized) OR b.klasse_id = ANY (klasse_candidates) )


            );

    klasse_candidates_is_initialized:=true;
    END LOOP;
END IF;

--/**********************//

IF coalesce(array_length(anyurnArr ,1),0)>0 THEN

    FOREACH anyurn IN ARRAY anyurnArr
    LOOP
        klasse_candidates:=array(
            SELECT DISTINCT
            b.klasse_id
            
            FROM  klasse_relation a
            JOIN klasse_registrering b on a.klasse_registrering_id=b.id
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
		((NOT klasse_candidates_is_initialized) OR b.klasse_id = ANY (klasse_candidates) )


            );

    klasse_candidates_is_initialized:=true;
    END LOOP;
END IF;

--/**********************//

 




--RAISE DEBUG 'klasse_candidates_is_initialized step 5:%',klasse_candidates_is_initialized;
--RAISE DEBUG 'klasse_candidates step 5:%',klasse_candidates;

IF registreringObj IS NULL THEN
    --RAISE DEBUG 'registreringObj IS NULL';
ELSE
    IF NOT klasse_candidates_is_initialized THEN
        klasse_candidates:=array(
        SELECT DISTINCT
            klasse_id
        FROM
            klasse_registrering b
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
		((NOT klasse_candidates_is_initialized) OR b.klasse_id = ANY (klasse_candidates) )

        )
        ;

        klasse_candidates_is_initialized:=true;
    END IF;
END IF;


IF NOT klasse_candidates_is_initialized THEN
    --No filters applied!
    klasse_candidates:=array(
        SELECT DISTINCT id FROM klasse a
    );
ELSE
    klasse_candidates:=array(
        SELECT DISTINCT id FROM unnest(klasse_candidates) as a(id)
        );
END IF;

--RAISE DEBUG 'klasse_candidates_is_initialized step 6:%',klasse_candidates_is_initialized;
--RAISE DEBUG 'klasse_candidates step 6:%',klasse_candidates;


/*** Filter out the objects that does not meets the stipulated access criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_klasse(klasse_candidates,auth_criteria_arr); 
/*********************/
IF firstResult > 0 or maxResults < 2147483647 THEN
   auth_filtered_uuids = _as_sorted_klasse(auth_filtered_uuids, virkningSoeg, registreringObj, firstResult, maxResults);
END IF;
return auth_filtered_uuids;


END;
$$ LANGUAGE plpgsql STABLE; 




