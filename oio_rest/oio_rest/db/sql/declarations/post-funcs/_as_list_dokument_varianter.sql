-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0
CREATE OR REPLACE FUNCTION _as_list_dokument_varianter (dokument_uuids uuid[], registrering_tstzrange tstzrange, virkning_tstzrange tstzrange)
    RETURNS TABLE (dokument_registrering_id bigint, varianter DokumentVariantType[])
AS $BODY$
    SELECT
        a.dokument_registrering_id,
        _remove_nulls_in_array (array_agg(
                CASE WHEN (a.DokumentVariantEgenskaberTypeArr IS NOT NULL
                        AND coalesce(array_length(a.DokumentVariantEgenskaberTypeArr, 1), 0) > 0)
                    OR (a.variant_dele IS NOT NULL
                        AND coalesce(array_length(a.variant_dele, 1), 0) > 0) THEN
                    ROW (a.varianttekst, a.DokumentVariantEgenskaberTypeArr, a.variant_dele)::DokumentVariantType
                ELSE
                    NULL
                END)) varianter
    FROM (
        SELECT
            a.dokument_id,
            a.dokument_registrering_id,
            a.variant_id,
            a.varianttekst,
            a.DokumentVariantEgenskaberTypeArr,
            _remove_nulls_in_array (array_agg(
                    CASE WHEN (a.DokumentDelEgenskaberTypeArr IS NOT NULL
                            AND coalesce(array_length(a.DokumentDelEgenskaberTypeArr, 1), 0) > 0)
                        OR (a.DokumentdelRelationTypeArr IS NOT NULL
                            AND coalesce(array_length(a.DokumentdelRelationTypeArr, 1), 0) > 0) THEN
                        ROW (a.deltekst, a.DokumentDelEgenskaberTypeArr, a.DokumentdelRelationTypeArr)::DokumentDelType
                    ELSE
                        NULL
                    END
                ORDER BY
                    a.deltekst)) variant_dele
        FROM (
            SELECT
                a.dokument_id,
                a.dokument_registrering_id,
                a.variant_id,
                a.varianttekst,
                a.DokumentVariantEgenskaberTypeArr,
                a.del_id,
                a.deltekst,
                a.DokumentDelEgenskaberTypeArr,
                _remove_nulls_in_array (array_agg(
                        CASE WHEN b.id IS NOT NULL THEN
                            ROW (b.rel_type, b.virkning, b.rel_maal_uuid, b.rel_maal_urn, b.objekt_type)::DokumentdelRelationType
                        ELSE
                            NULL
                        END
                    ORDER BY
                        b.rel_maal_uuid, b.rel_maal_urn, b.rel_type, b.objekt_type, b.virkning)) DokumentdelRelationTypeArr
            FROM (
                SELECT
                    a.dokument_id,
                    a.dokument_registrering_id,
                    a.variant_id,
                    a.varianttekst,
                    a.DokumentVariantEgenskaberTypeArr,
                    b.id del_id,
                    b.deltekst,
                    _remove_nulls_in_array (array_agg(
                            CASE WHEN c.id IS NOT NULL THEN
                                ROW (c.indeks, c.indhold, c.lokation, c.mimetype, c.virkning)::DokumentDelEgenskaberType
                            ELSE
                                NULL
                            END
                        ORDER BY
                            c.indeks, c.indhold, c.lokation, c.mimetype, c.virkning)) DokumentDelEgenskaberTypeArr
                FROM (
                    SELECT
                        a.id dokument_id,
                        b.id dokument_registrering_id,
                        e.id variant_id,
                        e.varianttekst,
                        _remove_nulls_in_array (array_agg(
                                CASE WHEN c.id IS NOT NULL THEN
                                    ROW (c.arkivering, c.delvisscannet, c.offentliggoerelse, c.produktion, c.virkning)::DokumentVariantEgenskaberType
                                ELSE
                                    NULL
                                END
                            ORDER BY
                                c.arkivering, c.delvisscannet, c.offentliggoerelse, c.produktion, c.virkning)) DokumentVariantEgenskaberTypeArr
                    FROM
                        dokument a
                        JOIN dokument_registrering b ON b.dokument_id = a.id
                        JOIN dokument_variant e ON e.dokument_registrering_id = b.id
                        LEFT JOIN dokument_variant_egenskaber c ON c.variant_id = e.id
                            AND (virkning_tstzrange IS NULL
                                OR (c.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
                    WHERE
                        a.id = ANY (dokument_uuids)
                        AND ((registrering_tstzrange IS NULL
                                AND upper((b.registrering).timeperiod) = 'infinity'::TIMESTAMPTZ)
                            OR registrering_tstzrange && (b.registrering).timeperiod) --filter ON registrering_tstzrange
                    GROUP BY
                        a.id,
                        b.id,
                        e.id,
                        e.varianttekst) AS a
                LEFT JOIN dokument_del b ON a.variant_id = b.variant_id
                LEFT JOIN dokument_del_egenskaber c ON b.id = c.del_id
                    AND (virkning_tstzrange IS NULL
                        OR (c.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
                GROUP BY
                    a.dokument_id,
                    a.dokument_registrering_id,
                    a.variant_id,
                    a.varianttekst,
                    a.DokumentVariantEgenskaberTypeArr,
                    b.id,
                    b.deltekst) AS a
        LEFT JOIN dokument_del_relation b ON b.del_id = a.del_id
            AND (virkning_tstzrange IS NULL
                OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
        GROUP BY
            a.dokument_id,
            a.dokument_registrering_id,
            a.variant_id,
            a.varianttekst,
            a.DokumentVariantEgenskaberTypeArr,
            a.del_id,
            a.deltekst,
            a.DokumentDelEgenskaberTypeArr) AS a
    GROUP BY
        a.dokument_id,
        a.dokument_registrering_id,
        a.variant_id,
        a.varianttekst,
        a.DokumentVariantEgenskaberTypeArr) AS a
GROUP BY
    a.dokument_id,
    a.dokument_registrering_id
$BODY$ LANGUAGE sql STABLE;
