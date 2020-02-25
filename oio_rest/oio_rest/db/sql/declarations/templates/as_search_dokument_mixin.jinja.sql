-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--/**********************************************************//
--Filtration on variants and document parts (dele)
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).varianter IS NULL THEN
	--RAISE DEBUG 'as_search_dokument: skipping filtration on relationer';
ELSE
		IF (registreringObj).varianter IS NOT NULL AND coalesce(array_length(registreringObj.varianter,1),0)>0 THEN
		FOREACH variantTypeObj IN ARRAY registreringObj.varianter
		LOOP

		variant_candidates_ids=array[]::bigint[];
		variant_candidates_is_initialized:=false;

		IF (coalesce(array_length(dokument_candidates,1),0)>0 OR NOT dokument_candidates_is_initialized) THEN 

		--HACK: As variant_name logically can be said to be part of variant egenskaber (regarding virkning), we'll force a filter on variant egenskaber if needed
		IF coalesce(array_length(variantTypeObj.egenskaber,1),0)=0 AND variantTypeObj.varianttekst IS NOT NULL THEN
			variantTypeObj.egenskaber:=ARRAY[ROW(null,null,null,null,null)::DokumentVariantEgenskaberType]::DokumentVariantEgenskaberType[];
		END IF;

		IF coalesce(array_length(variantTypeObj.egenskaber,1),0)>0 THEN
		
		FOREACH variantEgenskaberTypeObj in ARRAY variantTypeObj.egenskaber
		LOOP

		IF (coalesce(array_length(variant_candidates_ids,1),0)>0 OR not variant_candidates_is_initialized) THEN

			IF variantTypeObj.varianttekst IS NOT NULL OR
				(
					(NOT (variantEgenskaberTypeObj.arkivering IS NULL))
					OR
					(NOT (variantEgenskaberTypeObj.delvisscannet IS NULL))
					OR
					(NOT (variantEgenskaberTypeObj.offentliggoerelse IS NULL))
					OR
					(NOT (variantEgenskaberTypeObj.produktion IS NULL))
				)
			 THEN --test if there is any data availiable for variant to filter on
			

			--part for searching on variant + egenskaber
			variant_candidates_ids:=array(
			SELECT DISTINCT
			a.id
			FROM dokument_variant a
			JOIN dokument_registrering b on a.dokument_registrering_id=b.id
			JOIN dokument_variant_egenskaber c on c.variant_id=a.id  --we require the presence egenskaber (variant name is logically part of it)
			WHERE
			(
				variantTypeObj.varianttekst IS NULL
				OR
				a.varianttekst ilike variantTypeObj.varianttekst
			)
			AND
			(
				(
				virkningSoeg IS NULL
				OR
				virkningSoeg && (c.virkning).TimePeriod
				)
			)
			AND
			(
				(
				variantEgenskaberTypeObj.virkning IS NULL
				OR 
				(variantEgenskaberTypeObj.virkning).TimePeriod && (c.virkning).TimePeriod 
				)
			)
			AND
				(
				variantEgenskaberTypeObj.virkning IS NULL
				OR
					(
						(
								(variantEgenskaberTypeObj.virkning).AktoerRef IS NULL OR (c.virkning).AktoerRef = (variantEgenskaberTypeObj.virkning).AktoerRef
						)
						AND
						(
								(variantEgenskaberTypeObj.virkning).AktoerTypeKode IS NULL OR (variantEgenskaberTypeObj.virkning).AktoerTypeKode=(c.virkning).AktoerTypeKode
						)
						AND
						(
								(variantEgenskaberTypeObj.virkning).NoteTekst IS NULL OR (c.virkning).NoteTekst ilike (variantEgenskaberTypeObj.virkning).NoteTekst
						)
					)
				)
			AND
			(
				
				(
					variantEgenskaberTypeObj.arkivering IS NULL
					OR
					variantEgenskaberTypeObj.arkivering = c.arkivering
				)
				AND
				(
					variantEgenskaberTypeObj.delvisscannet IS NULL
					OR
					variantEgenskaberTypeObj.delvisscannet = c.delvisscannet
				)
				AND
				(
					variantEgenskaberTypeObj.offentliggoerelse IS NULL 
					OR
					variantEgenskaberTypeObj.offentliggoerelse = c.offentliggoerelse
				)
				AND
				(
					variantEgenskaberTypeObj.produktion IS NULL  
					OR
					variantEgenskaberTypeObj.produktion = c.produktion
				)
				
			)
			AND
			{% include 'as_search_mixin_filter_reg.jinja.sql' %}
			AND ((NOT variant_candidates_is_initialized) OR a.id = ANY (variant_candidates_ids) )
			);

			variant_candidates_is_initialized:=true;

			END IF; --any variant candidates left

			END IF; --variant filter criterium exists
			END LOOP; --variant egenskaber

			
			END IF;--variantTypeObj.egenskaber exists  

			/**************    Dokument Dele        ******************/

			IF coalesce(array_length(variantTypeObj.dele,1),0)>0 THEN
			
			FOREACH delTypeObj IN ARRAY variantTypeObj.dele 
			LOOP

			--HACK: As del_name logically can be said to be part of del egenskaber (regarding virkning), we'll force a filter on del egenskaber if needed
			IF coalesce(array_length(delTypeObj.egenskaber,1),0)=0 AND delTypeObj.deltekst IS NOT NULL THEN
				delTypeObj.egenskaber:=ARRAY[ROW(null,null,null,null,null)::DokumentDelEgenskaberType]::DokumentDelEgenskaberType[];
			END IF;


			/**************    Dokument Del Egenskaber    ******************/

			IF coalesce(array_length(delTypeObj.egenskaber,1),0)>0 THEN 
			
			FOREACH delEgenskaberTypeObj IN ARRAY delTypeObj.egenskaber
			LOOP
			
			IF delTypeObj.deltekst IS NOT NULL  	
			OR (NOT delEgenskaberTypeObj.indeks IS NULL)
			OR delEgenskaberTypeObj.indhold IS NOT NULL
			OR delEgenskaberTypeObj.lokation IS NOT NULL
			OR delEgenskaberTypeObj.mimetype IS NOT NULL
			THEN 

			IF (coalesce(array_length(variant_candidates_ids,1),0)>0 OR not variant_candidates_is_initialized) THEN

			variant_candidates_ids:=array(
			SELECT DISTINCT
			a.id
			FROM dokument_variant a
			JOIN dokument_registrering b on a.dokument_registrering_id=b.id
			JOIN dokument_del c on c.variant_id=a.id
			JOIN dokument_del_egenskaber d on d.del_id=c.id --we require the presence egenskaber (del name is logically part of it)
		
			WHERE
			(
				delTypeObj.deltekst IS NULL
				OR
				c.deltekst ilike delTypeObj.deltekst
			)
			AND
			(
				virkningSoeg IS NULL
				OR
				virkningSoeg && (d.virkning).TimePeriod
			)
			AND
			(
				delEgenskaberTypeObj.virkning IS NULL --NOTICE only looking at first del egenskaber object throughout
				OR 
				(delEgenskaberTypeObj.virkning).TimePeriod && (d.virkning).TimePeriod 
			)
			AND
			(
				delEgenskaberTypeObj.virkning IS NULL
				OR
					(
						(
								(delEgenskaberTypeObj.virkning).AktoerRef IS NULL OR (d.virkning).AktoerRef = (delEgenskaberTypeObj.virkning).AktoerRef
						)
						AND
						(
								(delEgenskaberTypeObj.virkning).AktoerTypeKode IS NULL OR (delEgenskaberTypeObj.virkning).AktoerTypeKode=(d.virkning).AktoerTypeKode
						)
						AND
						(
								(delEgenskaberTypeObj.virkning).NoteTekst IS NULL OR (d.virkning).NoteTekst ilike (delEgenskaberTypeObj.virkning).NoteTekst
						)
					)
			)
			AND
			(
				(
					(
						delEgenskaberTypeObj.indeks IS NULL  
						OR
						delEgenskaberTypeObj.indeks = d.indeks
					)
					AND
					(
						delEgenskaberTypeObj.indhold IS NULL  
						OR
						d.indhold ilike delEgenskaberTypeObj.indhold  
					)
					AND
					(
						delEgenskaberTypeObj.lokation IS NULL 
						OR
						d.lokation ilike delEgenskaberTypeObj.lokation 
					)
					AND
					(
						delEgenskaberTypeObj.mimetype IS NULL 
						OR
						d.mimetype ilike delEgenskaberTypeObj.mimetype
					)
				)
			)
			AND
			{% include 'as_search_mixin_filter_reg.jinja.sql' %}
			AND ((NOT variant_candidates_is_initialized) OR a.id = ANY (variant_candidates_ids) )
			);

			variant_candidates_is_initialized:=true;
			END IF; --any variant candidates left
			END IF; --del egenskaber not empty
			END LOOP; --loop del egenskaber
			END IF; -- del egenskaber exists

			/**************    Dokument Del Relationer    ******************/

			IF coalesce(array_length(delTypeObj.relationer,1),0)>0 THEN 
			
			FOREACH delRelationTypeObj IN ARRAY delTypeObj.relationer
			LOOP

			IF (coalesce(array_length(variant_candidates_ids,1),0)>0 OR not variant_candidates_is_initialized) THEN

			variant_candidates_ids:=array(
			SELECT DISTINCT
			a.id
			FROM dokument_variant a
			JOIN dokument_registrering b on a.dokument_registrering_id=b.id
			JOIN dokument_del c on c.variant_id=a.id
			JOIN dokument_del_relation d on d.del_id=c.id
			WHERE
			(
				delTypeObj.deltekst IS NULL
				OR
				c.deltekst ilike delTypeObj.deltekst
			)
			AND
			(
				virkningSoeg IS NULL
				OR
				virkningSoeg && (d.virkning).TimePeriod
			)
			AND
			(
				delRelationTypeObj.virkning IS NULL 
				OR 
				(delRelationTypeObj.virkning).TimePeriod && (d.virkning).TimePeriod 
			)
			AND
			(
				delRelationTypeObj.virkning IS NULL
				OR
					(
						(
								(delRelationTypeObj.virkning).AktoerRef IS NULL OR (d.virkning).AktoerRef = (delRelationTypeObj.virkning).AktoerRef
						)
						AND
						(
								(delRelationTypeObj.virkning).AktoerTypeKode IS NULL OR (delRelationTypeObj.virkning).AktoerTypeKode=(d.virkning).AktoerTypeKode
						)
						AND
						(
								(delRelationTypeObj.virkning).NoteTekst IS NULL OR (d.virkning).NoteTekst ilike (delRelationTypeObj.virkning).NoteTekst
						)
					)
			)
			AND
			(	
				delRelationTypeObj.relType IS NULL
				OR
				delRelationTypeObj.relType = d.rel_type
			)
			AND
			(
				delRelationTypeObj.uuid IS NULL
				OR
				delRelationTypeObj.uuid = d.rel_maal_uuid	
			)
			AND
			(
				delRelationTypeObj.objektType IS NULL
				OR
				delRelationTypeObj.objektType = d.objekt_type
			)
			AND
			(
				delRelationTypeObj.urn IS NULL
				OR
				delRelationTypeObj.urn = d.rel_maal_urn
			)
			AND
			{% include 'as_search_mixin_filter_reg.jinja.sql' %}
			AND ((NOT variant_candidates_is_initialized) OR a.id = ANY (variant_candidates_ids) )
			);
			
			variant_candidates_is_initialized:=true;

			END IF; --any variant candidates left

			END LOOP; --loop del relationer
			END IF; --end if del relationer exists

			END LOOP; --loop del
			END IF;--dele exists


			
			IF variant_candidates_is_initialized THEN
			--We'll then translate the collected variant ids into document ids (please notice that the resulting uuids are already a subset of dokument_candidates)

			dokument_candidates:=array(
			SELECT DISTINCT
			b.dokument_id 
			FROM dokument_variant a
			JOIN dokument_registrering b on a.dokument_registrering_id=b.id
			WHERE
			a.id = ANY (variant_candidates_ids)
			AND
			((NOT dokument_candidates_is_initialized) OR b.dokument_id = ANY (dokument_candidates) )
			);

			dokument_candidates_is_initialized:=true;
			
			END IF; --variant_candidates_is_initialized

			END IF; --no doc candidates - skipping ahead;
			END LOOP; --FOREACH variantTypeObj
		
		END IF; --varianter exists
	END IF; --array registreringObj.varianter exists
