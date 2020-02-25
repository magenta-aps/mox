{% extends "basis.jinja.sql" %}

-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


{% block body %}

CREATE OR REPLACE FUNCTION as_search_{{oio_type}}(
    firstResult int,--TOOD ??
    {{oio_type}}_uuid uuid,
    registreringObj   {{oio_type|title}}RegistreringType,
    virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
    maxResults int = 2147483647,
    anyAttrValueArr text[] = '{}'::text[],
    anyuuidArr uuid[] = '{}'::uuid[],
    anyurnArr text[] = '{}'::text[],
    auth_criteria_arr {{oio_type|title}}RegistreringType[]=null

    {% if oio_type in ("aktivitet", "indsats") %},
    search_operator_greater_than_or_equal_attr_egenskaber {{oio_type|title}}EgenskaberAttrType[]=null,
    search_operator_less_than_or_equal_attr_egenskaber    {{oio_type|title}}EgenskaberAttrType[]=null
    {% endif %}

) RETURNS uuid[] AS $$
DECLARE
    {{oio_type}}_candidates uuid[];
    {{oio_type}}_candidates_is_initialized boolean;
    --to_be_applyed_filter_uuids uuid[];

    {%-for attribut, attribut_fields in attributter.items() %}
    attr{{attribut|title}}TypeObj {{oio_type|title}}{{attribut|title}}AttrType;
    {%- endfor %}

    {% for tilstand, tilstand_values in tilstande.items() %}
    tils{{tilstand|title}}TypeObj {{oio_type|title}}{{tilstand|title}}TilsType;
    {%- endfor %}

    relationTypeObj {{oio_type|title}}RelationType;
    anyAttrValue text;
    anyuuid uuid;
    anyurn text;

    {% if oio_type == "dokument" %}
    variantTypeObj DokumentVariantType;
    variantEgenskaberTypeObj DokumentVariantEgenskaberType;
    delTypeObj DokumentDelType;
    delEgenskaberTypeObj DokumentDelEgenskaberType;
    delRelationTypeObj DokumentdelRelationType;
    variant_candidates_ids bigint[];
    variant_candidates_is_initialized boolean;
    {% endif %}

    auth_filtered_uuids uuid[];

    {% if oio_type == "klasse" %}
    manipulatedAttrEgenskaberArr KlasseEgenskaberAttrType[]:='{}';
    soegeordObj KlasseSoegeordType;
    {% endif %}
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

{{oio_type}}_candidates_is_initialized := false;

IF {{oio_type}}_uuid is not NULL THEN
    {{oio_type}}_candidates:= ARRAY[{{oio_type}}_uuid];
    {{oio_type}}_candidates_is_initialized:=true;
    IF registreringObj IS NULL THEN
    --RAISE DEBUG 'no registreringObj'
    ELSE
        {{oio_type}}_candidates:=array(
                SELECT DISTINCT
                b.{{oio_type}}_id
                FROM
                {{oio_type}} a
                JOIN {{oio_type}}_registrering b on b.{{oio_type}}_id=a.id
                WHERE
                {% include 'as_search_mixin_filter_reg.jinja.sql' %}
        );
    END IF;
END IF;


--RAISE DEBUG '{{oio_type}}_candidates_is_initialized step 1:%',{{oio_type}}_candidates_is_initialized;
--RAISE DEBUG '{{oio_type}}_candidates step 1:%',{{oio_type}}_candidates;
--/****************************//


--RAISE NOTICE '{{oio_type}}_candidates_is_initialized step 2:%',{{oio_type}}_candidates_is_initialized;
--RAISE NOTICE '{{oio_type}}_candidates step 2:%',{{oio_type}}_candidates;

--/****************************//
--filter on attributes

{%-for attribut , attribut_fields in attributter.items() %} 
--/**********************************************************//
--Filtration on attribute: {{attribut|title}}
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attr{{attribut|title}} IS NULL THEN
    --RAISE DEBUG 'as_search_{{oio_type}}: skipping filtration on attr{{attribut|title}}';
ELSE
{% if oio_type == "klasse" %}

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
{% endif %}
    IF (coalesce(array_length({{oio_type}}_candidates,1),0)>0 OR NOT {{oio_type}}_candidates_is_initialized) THEN
        {% if oio_type == "klasse" %}
        FOREACH attr{{attribut|title}}TypeObj IN ARRAY manipulatedAttrEgenskaberArr
        {% else %}
        FOREACH attr{{attribut|title}}TypeObj IN ARRAY registreringObj.attr{{attribut|title}}
        {% endif %}
        LOOP
            {{oio_type}}_candidates:=array(
            SELECT DISTINCT
            b.{{oio_type}}_id
            FROM  {{oio_type}}_attr_{{attribut}} a
            JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id
            {% if oio_type == "klasse" %}
            LEFT JOIN klasse_attr_egenskaber_soegeord c on a.id=c.klasse_attr_egenskaber_id
            {% endif %}
            WHERE
                (
                    (
                        attr{{attribut|title}}TypeObj.virkning IS NULL 
                        OR
                        (
                            (
                                (
                                     (attr{{attribut|title}}TypeObj.virkning).TimePeriod IS NULL
                                )
                                OR
                                (
                                    (attr{{attribut|title}}TypeObj.virkning).TimePeriod && (a.virkning).TimePeriod
                                )
                            )
                            AND
                            (
                                    (attr{{attribut|title}}TypeObj.virkning).AktoerRef IS NULL OR (attr{{attribut|title}}TypeObj.virkning).AktoerRef=(a.virkning).AktoerRef
                            )
                            AND
                            (
                                    (attr{{attribut|title}}TypeObj.virkning).AktoerTypeKode IS NULL OR (attr{{attribut|title}}TypeObj.virkning).AktoerTypeKode=(a.virkning).AktoerTypeKode
                            )
                            AND
                            (
                                    (attr{{attribut|title}}TypeObj.virkning).NoteTekst IS NULL OR  (a.virkning).NoteTekst ILIKE (attr{{attribut|title}}TypeObj.virkning).NoteTekst  
                            )
                        )
                    )
                )
                AND
                (
                    (NOT (attr{{attribut|title}}TypeObj.virkning IS NULL OR (attr{{attribut|title}}TypeObj.virkning).TimePeriod IS NULL)) --we have already filtered on virkning above
                    OR
                    (
                        virkningSoeg IS NULL
                        OR
                        virkningSoeg && (a.virkning).TimePeriod
                    )
                )
                {%- for attribut_field in attribut_fields %}
                AND
                (
                    attr{{attribut|title}}TypeObj.{{attribut_field}} IS NULL
                    OR
                     {%- if attributter_metadata[attribut][attribut_field]['type'] %}
                        {%-if attributter_metadata[attribut][attribut_field]['type'] == "text[]" %}
                    _as_search_match_array(attr{{attribut|title}}TypeObj.{{attribut_field}},a.{{attribut_field}})  
                        {%- else %}
                        {%-if attributter_metadata[attribut][attribut_field]['type'] == "offentlighedundtagettype" %}
                        (
                            (
                                (attr{{attribut|title}}TypeObj.{{attribut_field}}).AlternativTitel IS NULL
                                OR
                                (a.{{attribut_field}}).AlternativTitel ILIKE (attr{{attribut|title}}TypeObj.{{attribut_field}}).AlternativTitel
                            )
                            AND
                            (
                                (attr{{attribut|title}}TypeObj.{{attribut_field}}).Hjemmel IS NULL
                                OR
                                (a.{{attribut_field}}).Hjemmel ILIKE (attr{{attribut|title}}TypeObj.{{attribut_field}}).Hjemmel
                            )
                        )
                        {%- else %}
                    a.{{attribut_field}} = attr{{attribut|title}}TypeObj.{{attribut_field}}
                        {%- endif %}
                        {%- endif %}
                    {%- else %}
                    a.{{attribut_field}} ILIKE attr{{attribut|title}}TypeObj.{{attribut_field}} --case insensitive
                    {%- endif %}
                )
                {%- endfor %}
                AND
                {% if oio_type == "klasse" %}
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
                {% endif %}
                {% include 'as_search_mixin_filter_reg.jinja.sql' %}
            );


            {{oio_type}}_candidates_is_initialized:=true;

        END LOOP;
    END IF;
END IF;





{%- endfor %}
--RAISE DEBUG '{{oio_type}}_candidates_is_initialized step 3:%',{{oio_type}}_candidates_is_initialized;
--RAISE DEBUG '{{oio_type}}_candidates step 3:%',{{oio_type}}_candidates;

--/**********************************************************//
--Filtration on anyAttrValueArr
--/**********************************************************//
IF coalesce(array_length(anyAttrValueArr ,1),0)>0 THEN

    FOREACH anyAttrValue IN ARRAY anyAttrValueArr
    LOOP
        {{oio_type}}_candidates:=array(

            {%-for attribut , attribut_fields in attributter.items() %}

            SELECT DISTINCT
            b.{{oio_type}}_id
            {% if oio_type == "dokument" %}
            FROM dokument_registrering b 
            LEFT JOIN dokument_attr_egenskaber a on a.dokument_registrering_id=b.id and (virkningSoeg IS NULL or virkningSoeg && (a.virkning).TimePeriod )
            LEFT JOIN dokument_variant c on c.dokument_registrering_id=b.id 
            LEFT JOIN dokument_del f on f.variant_id=c.id
            LEFT JOIN dokument_del_egenskaber d on d.del_id = f.id and (virkningSoeg IS NULL or virkningSoeg && (d.virkning).TimePeriod )
            LEFT JOIN dokument_variant_egenskaber e on e.variant_id = c.id and (virkningSoeg IS NULL or virkningSoeg && (e.virkning).TimePeriod )
            WHERE
            (
                (
                    a.brugervendtnoegle ILIKE anyAttrValue OR
                        a.beskrivelse ILIKE anyAttrValue OR
                                    a.brevdato::text ilike anyAttrValue OR
                        a.kassationskode ILIKE anyAttrValue OR
                                    a.major::text ilike anyAttrValue OR
                                    a.minor::text ilike anyAttrValue OR
                                    (a.offentlighedundtaget).Hjemmel ilike anyAttrValue OR (a.offentlighedundtaget).AlternativTitel ilike anyAttrValue OR
                        a.titel ILIKE anyAttrValue OR
                        a.dokumenttype ILIKE anyAttrValue
                )
                OR
                (
                    (c.varianttekst ilike anyAttrValue and e.id is not null) --varianttekst handled like it is logically part of variant egenskaber
                )
                OR
                (
                    (f.deltekst ilike anyAttrValue and d.id is not null ) --deltekst handled like it is logically part of del egenskaber
                    OR
                    d.indeks::text = anyAttrValue
                    OR
                    d.indhold ILIKE anyAttrValue
                    OR
                    d.lokation ILIKE anyAttrValue
                    OR
                    d.mimetype ILIKE anyAttrValue
                )
            )
            AND
            {% else %}
            FROM  {{oio_type}}_attr_{{attribut}} a
            JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id
            {% if oio_type == "klasse" %}
            LEFT JOIN klasse_attr_egenskaber_soegeord c on a.id=c.klasse_attr_egenskaber_id
            {% endif %}
            WHERE
            (
                {%- for attribut_field in attribut_fields %}
                    {%- if attributter_metadata[attribut][attribut_field]['type'] %}
                        {%-if attributter_metadata[attribut][attribut_field]['type'] == "text[]" %}
                              _as_search_ilike_array(anyAttrValue,a.{{attribut_field}})  {%- if (not loop.last)%} OR {%- endif %}
                        {%-else %}
                            {%-if attributter_metadata[attribut][attribut_field]['type'] == "boolean" %}
                                -- boolean is skipped intentionally
                                {% if (loop.last and loop.first)-%} FALSE {%- endif -%}
                            {%-else %}
                                {%-if attributter_metadata[attribut][attribut_field]['type'] == "offentlighedundtagettype" %}
                                    (a.{{attribut_field}}).Hjemmel ilike anyAttrValue OR (a.{{attribut_field}}).AlternativTitel ilike anyAttrValue {%- if (not loop.last)%} OR {%- endif %}
                                {%-else %}
                                    a.{{attribut_field}}::text ilike anyAttrValue  {%- if (not loop.last)%} OR {%- endif %}
                                {%- endif -%}
                            {%- endif -%}
                        {%- endif -%}
                    {%-else %}
                        a.{{attribut_field}} ILIKE anyAttrValue {%- if (not loop.last)%} OR {%- endif %}
                    {%- endif -%}
                {%- endfor %}
                {% if oio_type == "klasse" %}
                OR
                c.soegeordidentifikator ILIKE anyAttrValue
                OR
                c.beskrivelse ILIKE anyAttrValue
                OR
                c.soegeordskategori ILIKE anyAttrValue
                {% endif %}
            )
            AND
            (
                virkningSoeg IS NULL
                OR
                virkningSoeg && (a.virkning).TimePeriod
            )
            AND
            {% endif %}
            {% include 'as_search_mixin_filter_reg.jinja.sql' %}

            {%- if (not loop.last)%}
            UNION
            {%- endif %}
            {%- endfor %}

        );

    {{oio_type}}_candidates_is_initialized:=true;

    END LOOP;

END IF;



--RAISE DEBUG 'registrering,%',registreringObj;

{% for tilstand, tilstand_values in tilstande.items() %}
--/**********************************************************//
--Filtration on state: {{tilstand|title}}
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tils{{tilstand|title}} IS NULL THEN
    --RAISE DEBUG 'as_search_{{oio_type}}: skipping filtration on tils{{tilstand|title}}';
ELSE
    IF (coalesce(array_length({{oio_type}}_candidates,1),0)>0 OR {{oio_type}}_candidates_is_initialized IS FALSE ) THEN

        FOREACH tils{{tilstand|title}}TypeObj IN ARRAY registreringObj.tils{{tilstand|title}}
        LOOP
            {{oio_type}}_candidates:=array(
            SELECT DISTINCT
            b.{{oio_type}}_id
            FROM  {{oio_type}}_tils_{{tilstand}} a
            JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id
            WHERE
                (
                    tils{{tilstand|title}}TypeObj.virkning IS NULL
                    OR
                    (
                        (
                             (tils{{tilstand|title}}TypeObj.virkning).TimePeriod IS NULL
                            OR
                            (tils{{tilstand|title}}TypeObj.virkning).TimePeriod && (a.virkning).TimePeriod
                        )
                        AND
                        (
                                (tils{{tilstand|title}}TypeObj.virkning).AktoerRef IS NULL OR (tils{{tilstand|title}}TypeObj.virkning).AktoerRef=(a.virkning).AktoerRef
                        )
                        AND
                        (
                                (tils{{tilstand|title}}TypeObj.virkning).AktoerTypeKode IS NULL OR (tils{{tilstand|title}}TypeObj.virkning).AktoerTypeKode=(a.virkning).AktoerTypeKode
                        )
                        AND
                        (
                                (tils{{tilstand|title}}TypeObj.virkning).NoteTekst IS NULL OR (a.virkning).NoteTekst ILIKE (tils{{tilstand|title}}TypeObj.virkning).NoteTekst
                        )
                    )
                )
                AND
                (
                    (NOT ((tils{{tilstand|title}}TypeObj.virkning) IS NULL OR (tils{{tilstand|title}}TypeObj.virkning).TimePeriod IS NULL)) --we have already filtered on virkning above
                    OR
                    (
                        virkningSoeg IS NULL
                        OR
                        virkningSoeg && (a.virkning).TimePeriod
                    )
                )
                AND
                (
                    tils{{tilstand|title}}TypeObj.{{tilstand}} IS NULL
                    OR
                    tils{{tilstand|title}}TypeObj.{{tilstand}} = a.{{tilstand}}
                )
                AND
                {% include 'as_search_mixin_filter_reg.jinja.sql' %}
    );


            {{oio_type}}_candidates_is_initialized:=true;


        END LOOP;
    END IF;
END IF;

{%- endfor %}

/*
--relationer {{oio_type|title}}RelationType[]
*/


--RAISE DEBUG '{{oio_type}}_candidates_is_initialized step 4:%',{{oio_type}}_candidates_is_initialized;
--RAISE DEBUG '{{oio_type}}_candidates step 4:%',{{oio_type}}_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL THEN
    --RAISE DEBUG 'as_search_{{oio_type}}: skipping filtration on relationer';
ELSE
    IF (coalesce(array_length({{oio_type}}_candidates,1),0)>0 OR NOT {{oio_type}}_candidates_is_initialized) AND (registreringObj).relationer IS NOT NULL THEN
        FOREACH relationTypeObj IN ARRAY registreringObj.relationer
        LOOP
            {{oio_type}}_candidates:=array(
            SELECT DISTINCT
            b.{{oio_type}}_id
            FROM  {{oio_type}}_relation a
            JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id
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
                {% if oio_type == "sag" %}
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
                {% elif oio_type in ("aktivitet", "indsats") %}
                AND
                (
                        relationTypeObj.indeks IS NULL
                        OR
                        relationTypeObj.indeks = a.rel_index
                )
                {% endif %}
                {% if oio_type == "aktivitet" %}
                AND
                (
                        relationTypeObj.aktoerAttr IS NULL
                        OR
                        (
                                (
                                        (relationTypeObj.aktoerAttr).obligatorisk IS NULL
                                        OR
                                        (relationTypeObj.aktoerAttr).obligatorisk = (a.aktoer_attr).obligatorisk                                        
                                )
                                AND
                                (
                                        (relationTypeObj.aktoerAttr).accepteret IS NULL
                                        OR
                                        (relationTypeObj.aktoerAttr).accepteret = (a.aktoer_attr).accepteret
                                )
                                AND
                                (
                                        (relationTypeObj.aktoerAttr).repraesentation_uuid IS NULL
                                        OR
                                        (relationTypeObj.aktoerAttr).repraesentation_uuid = (a.aktoer_attr).repraesentation_uuid
                                )
                                AND
                                (
                                        (relationTypeObj.aktoerAttr).repraesentation_urn IS NULL
                                        OR
                                        (relationTypeObj.aktoerAttr).repraesentation_urn = (a.aktoer_attr).repraesentation_urn
                                )
                        )
                )
                {% elif oio_type == "tilstand" %}
                AND
                (
                        relationTypeObj.indeks IS NULL
                        OR
                        relationTypeObj.indeks = a.rel_index
                )
                AND
                (
                relationTypeObj.tilstandsVaerdiAttr IS NULL
                OR
                (
                        (
                                (relationTypeObj.tilstandsVaerdiAttr).nominelVaerdi IS NULL
                                OR
                                (a.tilstand_vaerdi_attr).nominelVaerdi ILIKE (relationTypeObj.tilstandsVaerdiAttr).nominelVaerdi
                        )
                        AND
                        (
                                (relationTypeObj.tilstandsVaerdiAttr).forventet IS NULL
                                OR
                                (a.tilstand_vaerdi_attr).forventet = (relationTypeObj.tilstandsVaerdiAttr).forventet
                        )
 
                )
                )
                {% endif %}
                AND
                {% include 'as_search_mixin_filter_reg.jinja.sql' %}
    );

            {{oio_type}}_candidates_is_initialized:=true;

        END LOOP;
    END IF;
END IF;
--/**********************//

IF coalesce(array_length(anyuuidArr ,1),0)>0 THEN

    FOREACH anyuuid IN ARRAY anyuuidArr
    LOOP
        {{oio_type}}_candidates:=array(
            SELECT DISTINCT
            b.{{oio_type}}_id
            {% if oio_type == "dokument" %}
            FROM dokument_registrering b  
            LEFT JOIN dokument_relation a on a.dokument_registrering_id=b.id and (virkningSoeg IS NULL or (virkningSoeg && (a.virkning).TimePeriod) )
            LEFT JOIN dokument_variant c on c.dokument_registrering_id=b.id
            LEFT JOIN dokument_del d on d.variant_id=c.id 
            LEFT JOIN dokument_del_relation e on d.id=e.del_id and (virkningSoeg IS NULL or (virkningSoeg && (e.virkning).TimePeriod) )
            WHERE
            (anyuuid = a.rel_maal_uuid OR anyuuid = e.rel_maal_uuid)
            {% else %}
            FROM  {{oio_type}}_relation a
            JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id
            WHERE
            {% if oio_type == "aktivitet" %}
            (
                    anyuuid = a.rel_maal_uuid
            OR  
                    ((NOT (a.aktoer_attr IS NULL)) AND anyuuid = (a.aktoer_attr).repraesentation_uuid )
            )
            {% else %}
            anyuuid = a.rel_maal_uuid
            {% endif %}
            AND
            (
                virkningSoeg IS NULL
                OR
                virkningSoeg && (a.virkning).TimePeriod
            )
            {% endif %}
            AND
            {% include 'as_search_mixin_filter_reg.jinja.sql' %}

            );

    {{oio_type}}_candidates_is_initialized:=true;
    END LOOP;
END IF;

--/**********************//

IF coalesce(array_length(anyurnArr ,1),0)>0 THEN

    FOREACH anyurn IN ARRAY anyurnArr
    LOOP
        {{oio_type}}_candidates:=array(
            SELECT DISTINCT
            b.{{oio_type}}_id
            {% if oio_type == "dokument" %}
            FROM dokument_registrering b  
            LEFT JOIN dokument_relation a on a.dokument_registrering_id=b.id and (virkningSoeg IS NULL or virkningSoeg && (a.virkning).TimePeriod )
            LEFT JOIN dokument_variant c on c.dokument_registrering_id=b.id
            LEFT JOIN dokument_del d on d.variant_id=c.id
            LEFT JOIN dokument_del_relation e on d.id=e.del_id and (virkningSoeg IS NULL or virkningSoeg && (e.virkning).TimePeriod)
            WHERE
            (anyurn = a.rel_maal_urn OR anyurn = e.rel_maal_urn)
            {% else %}
            FROM  {{oio_type}}_relation a
            JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id
            WHERE
            {% if oio_type == "aktivitet" %}
            (
            anyurn = a.rel_maal_urn
                    OR 
                   ((NOT (a.aktoer_attr IS NULL)) AND anyurn = (a.aktoer_attr).repraesentation_urn)
            )
            {% else %}
            anyurn = a.rel_maal_urn
            {% endif %}
            AND
            (
                virkningSoeg IS NULL
                OR
                virkningSoeg && (a.virkning).TimePeriod
            )
            {% endif %}
            AND
            {% include 'as_search_mixin_filter_reg.jinja.sql' %}

            );

    {{oio_type}}_candidates_is_initialized:=true;
    END LOOP;
END IF;

--/**********************//

{% include include_mixin  %} 

{% if oio_type in ("aktivitet", "indsats") %}
 --/**********************************************************//
---Filtration using operator 'greather than or equal': Egenskaber
---/**********************************************************//
IF coalesce(array_length(search_operator_greater_than_or_equal_attr_egenskaber,1),0)>0 THEN
       IF (coalesce(array_length({{oio_type}}_candidates,1),0)>0 OR NOT {{oio_type}}_candidates_is_initialized) THEN
               FOREACH attrEgenskaberTypeObj IN ARRAY search_operator_greater_than_or_equal_attr_egenskaber
               LOOP
                       {{oio_type}}_candidates:=array(
                       SELECT DISTINCT
                       b.{{oio_type}}_id 
                       FROM  {{oio_type}}_attr_egenskaber a
                       JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id
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
                                       a.brugervendtnoegle >= attrEgenskaberTypeObj.brugervendtnoegle 
                               )
                               {% if oio_type == "aktivitet" %}
                               AND
                               (
                                       attrEgenskaberTypeObj.{{oio_type}}navn IS NULL
                                       OR 
                                       a.{{oio_type}}navn >= attrEgenskaberTypeObj.{{oio_type}}navn 
                               )
                               {% endif %}
                               AND
                               (
                                       attrEgenskaberTypeObj.beskrivelse IS NULL
                                       OR 
                                       a.beskrivelse >= attrEgenskaberTypeObj.beskrivelse 
                               )
                               AND
                               (
                                       attrEgenskaberTypeObj.starttidspunkt IS NULL
                                       OR 
                                       a.starttidspunkt >= attrEgenskaberTypeObj.starttidspunkt 
                               )
                               AND
                               (
                                       attrEgenskaberTypeObj.sluttidspunkt IS NULL
                                       OR 
                                       a.sluttidspunkt >= attrEgenskaberTypeObj.sluttidspunkt 
                               )
                               {% if oio_type == "aktivitet" %}
                               AND
                               (
                                       attrEgenskaberTypeObj.tidsforbrug IS NULL
                                       OR 
                                       a.tidsforbrug >= attrEgenskaberTypeObj.tidsforbrug 
                               )
                               AND
                               (
                                       attrEgenskaberTypeObj.formaal IS NULL
                                       OR 
                                       a.formaal >= attrEgenskaberTypeObj.formaal 
                               )
                               {% endif %}
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
               ((NOT {{oio_type}}_candidates_is_initialized) OR b.{{oio_type}}_id = ANY ({{oio_type}}_candidates) )

                       );
                       

                       {{oio_type}}_candidates_is_initialized:=true;
                       
                       
                       END LOOP;
               END IF; 
       END IF;

--RAISE DEBUG '{{oio_type}}_candidates_is_initialized step 3:%',{{oio_type}}_candidates_is_initialized;
--RAISE DEBUG '{{oio_type}}_candidates step 3:%',{{oio_type}}_candidates;

 --/**********************************************************//
--Filtration using operator 'less than or equal': Egenskaber
--/**********************************************************//
IF coalesce(array_length(search_operator_less_than_or_equal_attr_egenskaber,1),0)>0 THEN
       IF (coalesce(array_length({{oio_type}}_candidates,1),0)>0 OR NOT {{oio_type}}_candidates_is_initialized) THEN
               FOREACH attrEgenskaberTypeObj IN ARRAY search_operator_less_than_or_equal_attr_egenskaber
               LOOP
                       {{oio_type}}_candidates:=array(
                       SELECT DISTINCT
                       b.{{oio_type}}_id 
                       FROM  {{oio_type}}_attr_egenskaber a
                       JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id
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
                                       a.brugervendtnoegle <= attrEgenskaberTypeObj.brugervendtnoegle 
                               )
                               {% if oio_type == "aktivitet" %}
                               AND
                               (
                                       attrEgenskaberTypeObj.{{oio_type}}navn IS NULL
                                       OR 
                                       a.{{oio_type}}navn <= attrEgenskaberTypeObj.{{oio_type}}navn 
                               )
                               {% endif %}
                               AND
                               (
                                       attrEgenskaberTypeObj.beskrivelse IS NULL
                                       OR 
                                       a.beskrivelse <= attrEgenskaberTypeObj.beskrivelse 
                               )
                               AND
                               (
                                       attrEgenskaberTypeObj.starttidspunkt IS NULL
                                       OR 
                                       a.starttidspunkt <= attrEgenskaberTypeObj.starttidspunkt 
                               )
                               AND
                               (
                                       attrEgenskaberTypeObj.sluttidspunkt IS NULL
                                       OR 
                                       a.sluttidspunkt <= attrEgenskaberTypeObj.sluttidspunkt 
                               )
                               {% if oio_type == "aktivitet" %}
                               AND
                               (
                                       attrEgenskaberTypeObj.tidsforbrug IS NULL
                                       OR 
                                       a.tidsforbrug <= attrEgenskaberTypeObj.tidsforbrug 
                               )
                               AND
                               (
                                       attrEgenskaberTypeObj.formaal IS NULL
                                       OR 
                                       a.formaal <= attrEgenskaberTypeObj.formaal 
                               )
                               {% endif %}
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
               ((NOT {{oio_type}}_candidates_is_initialized) OR b.{{oio_type}}_id = ANY ({{oio_type}}_candidates) )

                       );
                       

                       {{oio_type}}_candidates_is_initialized:=true;
                       
                       
                       END LOOP;
               END IF; 
       END IF;

--RAISE DEBUG '{{oio_type}}_candidates_is_initialized step 3:%',{{oio_type}}_candidates_is_initialized;
--RAISE DEBUG '{{oio_type}}_candidates step 3:%',{{oio_type}}_candidates;

--/**********************//
{% endif %}


--RAISE DEBUG '{{oio_type}}_candidates_is_initialized step 5:%',{{oio_type}}_candidates_is_initialized;
--RAISE DEBUG '{{oio_type}}_candidates step 5:%',{{oio_type}}_candidates;

IF registreringObj IS NULL THEN
    --RAISE DEBUG 'registreringObj IS NULL';
ELSE
    IF NOT {{oio_type}}_candidates_is_initialized THEN
        {{oio_type}}_candidates:=array(
        SELECT DISTINCT
            {{oio_type}}_id
        FROM
            {{oio_type}}_registrering b
        WHERE
        {% include 'as_search_mixin_filter_reg.jinja.sql' %}
        )
        ;

        {{oio_type}}_candidates_is_initialized:=true;
    END IF;
END IF;


IF NOT {{oio_type}}_candidates_is_initialized THEN
    --No filters applied!
    {{oio_type}}_candidates:=array(
        SELECT DISTINCT id FROM {{oio_type}} a
    );
ELSE
    {{oio_type}}_candidates:=array(
        SELECT DISTINCT id FROM unnest({{oio_type}}_candidates) as a(id)
        );
END IF;

--RAISE DEBUG '{{oio_type}}_candidates_is_initialized step 6:%',{{oio_type}}_candidates_is_initialized;
--RAISE DEBUG '{{oio_type}}_candidates step 6:%',{{oio_type}}_candidates;


/*** Filter out the objects that does not meets the stipulated access criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_{{oio_type}}({{oio_type}}_candidates,auth_criteria_arr); 
/*********************/
IF firstResult > 0 or maxResults < 2147483647 THEN
   auth_filtered_uuids = _as_sorted_{{oio_type}}(auth_filtered_uuids, virkningSoeg, registreringObj, firstResult, maxResults);
END IF;
return auth_filtered_uuids;


END;
$$ LANGUAGE plpgsql STABLE; 



{% endblock %}
