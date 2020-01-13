{% extends "basis.jinja.sql" %}

-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


{% block body %}


/*************** FUNCTIONS (NEEDED FOR TABLE/INDEX-DEFS) DEFS ***************/

CREATE OR REPLACE FUNCTION _as_convert_{{oio_type}}_relation_kode_to_txt(
    {{oio_type|title}}RelationKode
) RETURNS TEXT LANGUAGE sql STRICT IMMUTABLE AS $$
    SELECT $1::text;
$$;


/****************************** TBLS DEFS ***********************************/

CREATE TABLE {{oio_type}} (
    id uuid NOT NULL,
    CONSTRAINT {{oio_type}}_pkey PRIMARY KEY (id)
)
WITH (
    OIDS=FALSE
);
ALTER TABLE {{oio_type}}
    OWNER TO mox;


/****************************************************************************/

CREATE SEQUENCE {{oio_type}}_registrering_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE {{oio_type}}_registrering_id_seq
    OWNER TO mox;


CREATE TABLE {{oio_type}}_registrering (
   id bigint NOT NULL DEFAULT nextval('{{oio_type}}_registrering_id_seq'::regclass),
   {{oio_type}}_id uuid NOT NULL ,
   registrering RegistreringBase NOT NULL CHECK( (registrering).TimePeriod IS NOT NULL AND not isempty((registrering).timeperiod) ),
   CONSTRAINT {{oio_type}}_registrering_pkey PRIMARY KEY (id),
   CONSTRAINT {{oio_type}}_registrering_{{oio_type}}_fkey FOREIGN KEY ({{oio_type}}_id)
       REFERENCES {{oio_type}} (id) MATCH SIMPLE
       ON UPDATE NO ACTION ON DELETE NO ACTION,
   CONSTRAINT {{oio_type}}_registrering__uuid_to_text_timeperiod_excl EXCLUDE 
   USING gist (_uuid_to_text({{oio_type}}_id) WITH =, _composite_type_to_time_range(registrering) WITH &&)
)
WITH (
  OIDS=FALSE
);

ALTER TABLE {{oio_type}}_registrering
  OWNER TO mox;


CREATE INDEX {{oio_type}}_registrering_idx_livscykluskode
    ON {{oio_type}}_registrering
    USING btree
    (((registrering).livscykluskode));


CREATE INDEX {{oio_type}}_registrering_idx_brugerref
    ON {{oio_type}}_registrering
    USING btree
    (((registrering).brugerref));


CREATE INDEX {{oio_type}}_registrering_idx_note
    ON {{oio_type}}_registrering
    USING btree
    (((registrering).note));


CREATE INDEX {{oio_type}}_registrering_pat_note
    ON {{oio_type}}_registrering
    USING gin
    (((registrering).note) gin_trgm_ops);


CREATE INDEX {{oio_type}}_id_idx
    ON {{oio_type}}_registrering ({{oio_type}}_id);


CREATE TRIGGER notify_{{oio_type}}
    AFTER INSERT OR UPDATE OR DELETE ON {{oio_type}}_registrering
    FOR EACH ROW EXECUTE PROCEDURE notify_event();


/****************************************************************************/

{% for attribut, attribut_fields in attributter.items() %}

CREATE SEQUENCE {{oio_type}}_attr_{{attribut}}_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;

ALTER TABLE {{oio_type}}_attr_{{attribut}}_id_seq
    OWNER TO mox;


CREATE TABLE {{oio_type}}_attr_{{attribut}} (
    id bigint NOT NULL DEFAULT nextval('{{oio_type}}_attr_{{attribut}}_id_seq'::regclass),
    {%- for field in attribut_fields %}
        {{ field }} {% if attributter_metadata[attribut][field]['type'] | default(False, True) -%}
            {{ attributter_metadata[attribut][field]['type'] }}
        {%- else -%}
            text
        {%- endif %} {% if attributter_metadata[attribut][field]['mandatory'] -%}
            NOT
        {%- endif %} NULL,
    {%- endfor %}
    virkning Virkning NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND NOT isempty((virkning).TimePeriod) ),
    {{oio_type}}_registrering_id bigint NOT NULL,
    CONSTRAINT {{oio_type}}_attr_{{attribut}}_pkey PRIMARY KEY (id),
    CONSTRAINT {{oio_type}}_attr_{{attribut}}_forkey_{{oio_type}}registrering FOREIGN KEY ({{oio_type}}_registrering_id) REFERENCES {{oio_type}}_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT {{oio_type}}_attr_{{attribut}}_exclude_virkning_overlap EXCLUDE USING gist ({{oio_type}}_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
    OIDS=FALSE
);

ALTER TABLE {{oio_type}}_attr_{{attribut}}
  OWNER TO mox;


{% for field in attribut_fields %} 
    {% if attributter_metadata[attribut][field]['type'] is defined %}
        {% if attributter_metadata[attribut][field]['type'] != "text[]" %}
            {% if attributter_metadata[attribut][field]['type'] == "offentlighedundtagettype" %} 
                CREATE INDEX {{oio_type}}_attr_{{attribut}}_pat_AlternativTitel_{{field}}
                    ON {{oio_type}}_attr_{{attribut}}
                    USING gin
                    ( (({{field}}).AlternativTitel) gin_trgm_ops);

                CREATE INDEX {{oio_type}}_attr_{{attribut}}_idx_AlternativTitel_{{field}}
                    ON {{oio_type}}_attr_{{attribut}}
                    USING btree
                    ((({{field}}).AlternativTitel));

                CREATE INDEX {{oio_type}}_attr_{{attribut}}_pat_Hjemmel_{{field}}
                    ON {{oio_type}}_attr_{{attribut}}
                    USING gin
                    ((({{field}}).Hjemmel) gin_trgm_ops);

                CREATE INDEX {{oio_type}}_attr_{{attribut}}_idx_Hjemmel_{{field}}
                    ON {{oio_type}}_attr_{{attribut}}
                    USING btree
                    ((({{field}}).Hjemmel));
            {% else %} 
                CREATE INDEX {{oio_type}}_attr_{{attribut}}_idx_{{field}}
                    ON {{oio_type}}_attr_{{attribut}}
                    USING btree
                    ({{field}});

            {% endif %}
        {% endif %} 
    {% else %} 
        CREATE INDEX {{oio_type}}_attr_{{attribut}}_pat_{{field}}
            ON {{oio_type}}_attr_{{attribut}}
            USING gin
            ({{field}} gin_trgm_ops);

        CREATE INDEX {{oio_type}}_attr_{{attribut}}_idx_{{field}}
            ON {{oio_type}}_attr_{{attribut}}
            USING btree
            ({{field}});
    {%- endif %} 
{% endfor %}


CREATE INDEX {{oio_type}}_attr_{{attribut}}_idx_virkning_aktoerref
    ON {{oio_type}}_attr_{{attribut}}
    USING btree
    (((virkning).aktoerref));

CREATE INDEX {{oio_type}}_attr_{{attribut}}_idx_virkning_aktoertypekode
    ON {{oio_type}}_attr_{{attribut}}
    USING btree
    (((virkning).aktoertypekode));

CREATE INDEX {{oio_type}}_attr_{{attribut}}_idx_virkning_notetekst
    ON {{oio_type}}_attr_{{attribut}}
    USING btree
    (((virkning).notetekst));

CREATE INDEX {{oio_type}}_attr_{{attribut}}_pat_virkning_notetekst
    ON {{oio_type}}_attr_{{attribut}}
    USING gin
    (((virkning).notetekst) gin_trgm_ops);

{% endfor %}


{% if oio_type == "klasse" %}
CREATE SEQUENCE klasse_attr_egenskaber_soegeord_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE klasse_attr_egenskaber_soegeord_id_seq
    OWNER TO mox;

CREATE TABLE klasse_attr_egenskaber_soegeord (
    id bigint NOT NULL DEFAULT nextval('klasse_attr_egenskaber_soegeord_id_seq'::regclass),
    soegeordidentifikator text null,
    beskrivelse text null,
    soegeordskategori text null,
    klasse_attr_egenskaber_id bigint not null,
    CONSTRAINT klasse_attr_egenskaber_soegeord_pkey PRIMARY KEY (id),
    CONSTRAINT klasse_attr_egenskaber_soegeord_forkey_klasse_attr_egenskaber FOREIGN KEY (klasse_attr_egenskaber_id) REFERENCES klasse_attr_egenskaber (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT klasse_attr_egenskaber_soegeord_chk_not_all_null CHECK (NOT (soegeordidentifikator IS NULL AND beskrivelse IS NULL AND soegeordskategori IS NULL))
)
WITH (
    OIDS=FALSE
);

ALTER TABLE klasse_attr_egenskaber_soegeord
    OWNER TO mox;


CREATE INDEX klasse_attr_egenskaber_soegeord_idx_soegeordidentifikator
    ON klasse_attr_egenskaber_soegeord
    USING btree
    (soegeordidentifikator);

CREATE INDEX klasse_attr_egenskaber_soegeord_pat_soegeordidentifikator
    ON klasse_attr_egenskaber_soegeord
    USING gin
    (soegeordidentifikator gin_trgm_ops);

CREATE INDEX klasse_attr_egenskaber_soegeord_idx_beskrivelse
    ON klasse_attr_egenskaber_soegeord
    USING btree
    (beskrivelse);

CREATE INDEX klasse_attr_egenskaber_soegeord_pat_beskrivelse
    ON klasse_attr_egenskaber_soegeord
    USING gin
    (beskrivelse gin_trgm_ops);

CREATE INDEX klasse_attr_egenskaber_soegeord_idx_soegeordskategori
    ON klasse_attr_egenskaber_soegeord
    USING btree
    (soegeordskategori);

CREATE INDEX klasse_attr_egenskaber_soegeord_pat_soegeordskategori
    ON klasse_attr_egenskaber_soegeord
    USING gin
    (soegeordskategori gin_trgm_ops);
{% endif %}


/****************************************************************************/

{% for tilstand, tilstand_values in tilstande.items() %}

CREATE SEQUENCE {{oio_type}}_tils_{{tilstand}}_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE {{oio_type}}_tils_{{tilstand}}_id_seq
    OWNER TO mox;


CREATE TABLE {{oio_type}}_tils_{{tilstand}} (
    id bigint NOT NULL DEFAULT nextval('{{oio_type}}_tils_{{tilstand}}_id_seq'::regclass),
    virkning Virkning NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
    {{tilstand}} {{oio_type|title}}{{tilstand|title}}Tils NOT NULL, 
    {{oio_type}}_registrering_id bigint not null,
    CONSTRAINT {{oio_type}}_tils_{{tilstand}}_pkey PRIMARY KEY (id),
    CONSTRAINT {{oio_type}}_tils_{{tilstand}}_forkey_{{oio_type}}registrering FOREIGN KEY ({{oio_type}}_registrering_id) REFERENCES {{oio_type}}_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT {{oio_type}}_tils_{{tilstand}}_exclude_virkning_overlap EXCLUDE USING gist ({{oio_type}}_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
    OIDS=FALSE
);

ALTER TABLE {{oio_type}}_tils_{{tilstand}}
    OWNER TO mox;


CREATE INDEX {{oio_type}}_tils_{{tilstand}}_idx_{{tilstand}}
    ON {{oio_type}}_tils_{{tilstand}}
    USING btree
    ({{tilstand}});
  
CREATE INDEX {{oio_type}}_tils_{{tilstand}}_idx_virkning_aktoerref
    ON {{oio_type}}_tils_{{tilstand}}
    USING btree
    (((virkning).aktoerref));

CREATE INDEX {{oio_type}}_tils_{{tilstand}}_idx_virkning_aktoertypekode
    ON {{oio_type}}_tils_{{tilstand}}
    USING btree
    (((virkning).aktoertypekode));

CREATE INDEX {{oio_type}}_tils_{{tilstand}}_idx_virkning_notetekst
    ON {{oio_type}}_tils_{{tilstand}}
    USING btree
    (((virkning).notetekst));

CREATE INDEX {{oio_type}}_tils_{{tilstand}}_pat_virkning_notetekst
    ON {{oio_type}}_tils_{{tilstand}}
    USING gin
    (((virkning).notetekst) gin_trgm_ops);
{% endfor %}


/****************************************************************************/

CREATE SEQUENCE {{oio_type}}_relation_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE {{oio_type}}_relation_id_seq
    OWNER TO mox;


CREATE TABLE {{oio_type}}_relation (
    id bigint NOT NULL DEFAULT nextval('{{oio_type}}_relation_id_seq'::regclass),
    {{oio_type}}_registrering_id bigint not null,
    virkning Virkning not null CHECK((virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
    --we have to allow null values (for now at least), as it is needed to be able to clear/overrule previous registered relations.
    rel_maal_uuid uuid NULL,
    rel_maal_urn text null,
    rel_type {{oio_type|title}}RelationKode not null,
    objekt_type text null,

    {% if oio_type == "aktivitet" %}
    rel_index int null,
    aktoer_attr AktivitetAktoerAttr null,
    {% elif oio_type == "indsats" %}
    rel_index int null,
    {% elif oio_type == "sag" %}
    rel_index int null,
    rel_type_spec SagRelationJournalPostSpecifikKode null,
    journal_notat JournalNotatType null,
    journal_dokument_attr JournalPostDokumentAttrType null,
    {% elif oio_type == "tilstand" %}
    rel_index int null,
    tilstand_vaerdi_attr TilstandVaerdiRelationAttrType null,
    {% endif %}

    CONSTRAINT {{oio_type}}_relation_forkey_{{oio_type}}registrering FOREIGN KEY ({{oio_type}}_registrering_id) REFERENCES {{oio_type}}_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT {{oio_type}}_relation_pkey PRIMARY KEY (id),
    CONSTRAINT {{oio_type}}_relation_no_virkning_overlap EXCLUDE USING gist ({{oio_type}}_registrering_id WITH =, _as_convert_{{oio_type}}_relation_kode_to_txt(rel_type) WITH =, _composite_type_to_time_range(virkning) WITH &&) {% if relationer_nul_til_mange %} WHERE ({% for nul_til_mange_rel in relationer_nul_til_mange %} rel_type<>('{{nul_til_mange_rel}}'::{{oio_type|title}}RelationKode ){% if not loop.last %} AND{% endif %}{% endfor %}) {% endif %},-- no overlapping virkning except for 0..n --relations
    CONSTRAINT {{oio_type}}_relation_either_uri_or_urn CHECK (NOT (rel_maal_uuid IS NOT NULL AND (rel_maal_urn IS NOT NULL AND rel_maal_urn<>''))){% if oio_type == "aktivitet" %},
    CONSTRAINT aktivitet_relation_check_aktoer_attr_rel_type CHECK (aktoer_attr IS NULL OR rel_type=('udfoerer'::AktivitetRelationKode) OR rel_type=('deltager'::AktivitetRelationKode) OR rel_type=('ansvarlig'::AktivitetRelationKode)),
    CONSTRAINT aktivitet_relation_aktoer_repr_either_uri_or_urn CHECK (aktoer_attr IS NULL OR ( _aktivitet_aktoer_attr_repr_uuid_to_text(aktoer_attr) IS NULL AND _aktivitet_aktoer_attr_repr_urn_to_text(aktoer_attr) IS NULL ) OR ((_aktivitet_aktoer_attr_repr_urn_to_text(aktoer_attr) IS NOT NULL AND _aktivitet_aktoer_attr_repr_uuid_to_text(aktoer_attr) IS NULL ) OR (_aktivitet_aktoer_attr_repr_urn_to_text(aktoer_attr) IS NULL AND _aktivitet_aktoer_attr_repr_uuid_to_text(aktoer_attr) IS NOT NULL ))){% elif oio_type == "sag" %},
    CONSTRAINT sag_relation_rel_type_spec_null_other_than_journalpost CHECK (rel_type_spec IS NULL OR rel_type='journalpost'::SagRelationKode ),
    CONSTRAINT sag_relation_journal_dok_attr_only_vedlagtdok_tilakteretdok CHECK (journal_dokument_attr IS NULL OR rel_type_spec IN ('vedlagtdokument'::SagRelationJournalPostSpecifikKode,'tilakteretdokument'::SagRelationJournalPostSpecifikKode)),
    CONSTRAINT sag_journal_notat_only_for_notat_type CHECK (journal_notat IS NULL OR rel_type_spec='journalnotat' ){% elif oio_type == "tilstand" %},
    CONSTRAINT tilstand_relation_nominel_vaerdi_relevant_null_check CHECK (tilstand_vaerdi_attr IS NULL OR rel_type='tilstandsvaerdi'){% endif %}
);
ALTER TABLE {{oio_type}}_relation
  OWNER TO mox;


{% if oio_type == "aktivitet" %}
CREATE UNIQUE INDEX aktivitet_relation_unique_index_within_type
    ON aktivitet_relation (aktivitet_registrering_id,rel_type,rel_index)
    WHERE ( rel_type IN ('udfoererklasse'::AktivitetRelationKode,'deltagerklasse'::AktivitetRelationKode,'objektklasse'::AktivitetRelationKode,'resultatklasse'::AktivitetRelationKode,'grundlagklasse'::AktivitetRelationKode,'facilitetklasse'::AktivitetRelationKode,'adresse'::AktivitetRelationKode,'geoobjekt'::AktivitetRelationKode,'position'::AktivitetRelationKode,'facilitet'::AktivitetRelationKode,'lokale'::AktivitetRelationKode,'aktivitetdokument'::AktivitetRelationKode,'aktivitetgrundlag'::AktivitetRelationKode,'aktivitetresultat'::AktivitetRelationKode,'udfoerer'::AktivitetRelationKode,'deltager'::AktivitetRelationKode));

{% elif oio_type == "indsats" %}
CREATE UNIQUE INDEX indsats_relation_unique_index_within_type
    ON indsats_relation (indsats_registrering_id,rel_type,rel_index)
    WHERE ( rel_type IN ('indsatskvalitet'::IndsatsRelationKode,'indsatsaktoer'::IndsatsRelationKode,'samtykke'::IndsatsRelationKode,'indsatssag'::IndsatsRelationKode,'indsatsdokument'::IndsatsRelationKode));

{% elif oio_type == "sag" %}
CREATE UNIQUE INDEX sag_relation_unique_index_within_type
    ON sag_relation (sag_registrering_id,rel_type,rel_index)
    WHERE ( rel_type IN ('andetarkiv'::SagRelationKode,'andrebehandlere'::SagRelationKode,'sekundaerpart'::SagRelationKode,'andresager'::SagRelationKode,'byggeri'::SagRelationKode,'fredning'::SagRelationKode,'journalpost'::SagRelationKode));

{% elif oio_type == "tilstand" %}
CREATE UNIQUE INDEX tilstand_relation_unique_index_within_type
    ON tilstand_relation (tilstand_registrering_id,rel_type,rel_index)
    WHERE ( rel_type IN ('tilstandsvaerdi'::TilstandRelationKode,'begrundelse'::TilstandRelationKode,'tilstandskvalitet'::TilstandRelationKode,'tilstandsvurdering'::TilstandRelationKode,'tilstandsaktoer'::TilstandRelationKode,'tilstandsudstyr'::TilstandRelationKode,'samtykke'::TilstandRelationKode,'tilstandsdokument'::TilstandRelationKode));

{% endif %}


CREATE INDEX {{oio_type}}_relation_idx_rel_maal_obj_uuid
    ON {{oio_type}}_relation
    USING btree
    (rel_type,objekt_type,rel_maal_uuid);

{% if oio_type == "aktivitet" %}
CREATE INDEX aktivitet_relation_idx_repr_uuid
    ON aktivitet_relation
    USING btree
    (((aktoer_attr).repraesentation_uuid));

CREATE INDEX aktivitet_relation_idx_repr_urn
    ON aktivitet_relation
    USING btree
    (((aktoer_attr).repraesentation_urn));
{% endif %}

CREATE INDEX {{oio_type}}_relation_idx_rel_maal_obj_urn
    ON {{oio_type}}_relation
    USING btree
    (rel_type,objekt_type,rel_maal_urn);

CREATE INDEX {{oio_type}}_relation_idx_rel_maal_uuid
    ON {{oio_type}}_relation
    USING btree
    (rel_type, rel_maal_uuid);

CREATE INDEX {{oio_type}}_relation_idx_rel_maal_uuid_isolated
    ON {{oio_type}}_relation
    USING btree
    (rel_maal_uuid);

CREATE INDEX {{oio_type}}_relation_idx_rel_maal_urn_isolated
    ON {{oio_type}}_relation
    USING btree
    (rel_maal_urn);

CREATE INDEX {{oio_type}}_relation_idx_rel_maal_urn
    ON {{oio_type}}_relation
    USING btree
    (rel_type, rel_maal_urn);

CREATE INDEX {{oio_type}}_relation_idx_virkning_aktoerref
    ON {{oio_type}}_relation
    USING btree
    (((virkning).aktoerref));

CREATE INDEX {{oio_type}}_relation_idx_virkning_aktoertypekode
    ON {{oio_type}}_relation
    USING btree
    (((virkning).aktoertypekode));

CREATE INDEX {{oio_type}}_relation_idx_virkning_notetekst
    ON {{oio_type}}_relation
    USING btree
    (((virkning).notetekst));

CREATE INDEX {{oio_type}}_relation_pat_virkning_notetekst
    ON {{oio_type}}_relation
    USING gin
    (((virkning).notetekst) gin_trgm_ops);


{% if oio_type == "dokument" %}
/**********************************************************************/
/*                        dokument variant                            */
/**********************************************************************/

CREATE SEQUENCE dokument_variant_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE dokument_variant_id_seq
    OWNER TO mox;


CREATE TABLE dokument_variant(
    id bigint not null DEFAULT nextval('dokument_variant_id_seq'::regclass),
    varianttekst text NOT NULL,
    dokument_registrering_id bigint not null,
    UNIQUE(dokument_registrering_id,varianttekst),
    CONSTRAINT dokument_variant_pkey PRIMARY KEY (id),
    CONSTRAINT dokument_variant_forkey_dokumentregistrering FOREIGN KEY (dokument_registrering_id) REFERENCES dokument_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);

ALTER TABLE dokument_variant
  OWNER TO mox;


CREATE SEQUENCE dokument_variant_egenskaber_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE dokument_variant_egenskaber_id_seq
    OWNER TO mox;


CREATE TABLE dokument_variant_egenskaber(
    id bigint NOT NULL DEFAULT nextval('dokument_variant_egenskaber_id_seq'::regclass), 
    variant_id bigint not null, 
    arkivering boolean null, 
    delvisscannet boolean null, 
    offentliggoerelse boolean null, 
    produktion boolean null, 
    virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
    CONSTRAINT dokument_variant_egenskaber_pkey PRIMARY KEY (id),
    CONSTRAINT dokument_variant_egenskaber_forkey_dokumentvariant FOREIGN KEY (variant_id) REFERENCES dokument_variant (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT dokument_variant_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (variant_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE dokument_variant_egenskaber
    OWNER TO mox;

 
CREATE INDEX dokument_variant_egenskaber_idx_arkivering
    ON dokument_variant_egenskaber
    USING btree
    (arkivering); 

CREATE INDEX dokument_variant_egenskaber_idx_delvisscannet
    ON dokument_variant_egenskaber
    USING btree
    (delvisscannet); 
 
CREATE INDEX dokument_variant_egenskaber_idx_offentliggoerelse
    ON dokument_variant_egenskaber
    USING btree
    (offentliggoerelse); 
 
CREATE INDEX dokument_variant_egenskaber_idx_produktion
    ON dokument_variant_egenskaber
    USING btree
    (produktion); 

CREATE INDEX dokument_variant_egenskaber_idx_virkning_aktoerref
    ON dokument_variant_egenskaber
    USING btree
    (((virkning).aktoerref));

CREATE INDEX dokument_variant_egenskaber_idx_virkning_aktoertypekode
    ON dokument_variant_egenskaber
    USING btree
    (((virkning).aktoertypekode));

CREATE INDEX dokument_variant_egenskaber_idx_virkning_notetekst
    ON dokument_variant_egenskaber
    USING btree
    (((virkning).notetekst));

CREATE INDEX dokument_variant_egenskaber_pat_virkning_notetekst
    ON dokument_variant_egenskaber
    USING gin
    (((virkning).notetekst) gin_trgm_ops);


/**********************************************************************/
/*                        dokument del                                */
/**********************************************************************/

CREATE SEQUENCE dokument_del_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE dokument_del_id_seq
    OWNER TO mox;


CREATE TABLE dokument_del(
    id bigint not null DEFAULT nextval('dokument_del_id_seq'::regclass),
    deltekst text NOT NULL,
    variant_id bigint not null,
    UNIQUE (variant_id, deltekst),
    CONSTRAINT dokument_del_forkey_variant_id FOREIGN KEY (variant_id) REFERENCES dokument_variant (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT dokument_del_pkey PRIMARY KEY (id)
)
WITH (
    OIDS=FALSE
);

ALTER TABLE dokument_del
    OWNER TO mox;


CREATE SEQUENCE dokument_del_egenskaber_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE dokument_del_egenskaber_id_seq
    OWNER TO mox;


CREATE TABLE dokument_del_egenskaber(
    id bigint NOT NULL DEFAULT nextval('dokument_del_egenskaber_id_seq'::regclass), 
    del_id bigint NOT NULL,
    indeks int null, 
    indhold text null, 
    lokation text null, 
    mimetype text null, 
    virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
    CONSTRAINT dokument_del_egenskaber_pkey PRIMARY KEY (id),
    CONSTRAINT dokument_del_egenskaber_forkey_dokument_del FOREIGN KEY (del_id) REFERENCES dokument_del (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT dokument_del_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (del_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
    OIDS=FALSE
);

ALTER TABLE dokument_del_egenskaber
    OWNER TO mox;

CREATE INDEX dokument_del_egenskaber_idx_indeks
    ON dokument_del_egenskaber
    USING btree
    (indeks); 
 
CREATE INDEX dokument_del_egenskaber_pat_indhold
    ON dokument_del_egenskaber
    USING gin
    (indhold gin_trgm_ops);

CREATE INDEX dokument_del_egenskaber_idx_indhold
    ON dokument_del_egenskaber
    USING btree
    (indhold); 
 
CREATE INDEX dokument_del_egenskaber_pat_lokation
    ON dokument_del_egenskaber
    USING gin
    (lokation gin_trgm_ops);

CREATE INDEX dokument_del_egenskaber_idx_lokation
    ON dokument_del_egenskaber
    USING btree
    (lokation); 
 
CREATE INDEX dokument_del_egenskaber_pat_mimetype
    ON dokument_del_egenskaber
    USING gin
    (mimetype gin_trgm_ops);

CREATE INDEX dokument_del_egenskaber_idx_mimetype
    ON dokument_del_egenskaber
    USING btree
    (mimetype); 

CREATE INDEX dokument_del_egenskaber_idx_virkning_aktoerref
    ON dokument_del_egenskaber
    USING btree
    (((virkning).aktoerref));

CREATE INDEX dokument_del_egenskaber_idx_virkning_aktoertypekode
    ON dokument_del_egenskaber
    USING btree
    (((virkning).aktoertypekode));

CREATE INDEX dokument_del_egenskaber_idx_virkning_notetekst
    ON dokument_del_egenskaber
    USING btree
    (((virkning).notetekst));

CREATE INDEX dokument_del_egenskaber_pat_virkning_notetekst
    ON dokument_del_egenskaber
    USING gin
    (((virkning).notetekst) gin_trgm_ops);

CREATE SEQUENCE dokument_del_relation_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

ALTER TABLE dokument_del_relation_id_seq
  OWNER TO mox;


CREATE TABLE dokument_del_relation (
    id bigint NOT NULL DEFAULT nextval('dokument_del_relation_id_seq'::regclass),
    del_id bigint not null,
    virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
    rel_maal_uuid uuid NULL, 
    rel_maal_urn text null,
    rel_type DokumentdelRelationKode not null,
    objekt_type text null,
    CONSTRAINT dokument_del_relation_forkey_dokument_del FOREIGN KEY (del_id) REFERENCES dokument_del (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT dokument_del_relation_pkey PRIMARY KEY (id),
    -- CONSTRAINT dokument_del_relation_no_virkning_overlap EXCLUDE USING gist (dokument_del_registrering_id WITH =, _as_convert_dokument_del_relation_kode_to_txt(rel_type) WITH =, _composite_type_to_time_range(virkning) WITH &&)  WHERE ( rel_type<>('underredigeringaf'::dokument_delRelationKode )) ,-- no overlapping virkning except for 0..n --relations
    CONSTRAINT dokument_del_relation_either_uri_or_urn CHECK (NOT (rel_maal_uuid IS NOT NULL AND (rel_maal_urn IS NOT NULL AND rel_maal_urn<>'')))
);
ALTER TABLE dokument_del_relation
  OWNER TO mox;


CREATE INDEX dokument_del_relation_idx_rel_maal_obj_uuid
    ON dokument_del_relation
    USING btree
    (rel_type,objekt_type,rel_maal_uuid);

CREATE INDEX dokument_del_relation_idx_rel_maal_obj_urn
    ON dokument_del_relation
    USING btree
    (rel_type,objekt_type,rel_maal_urn);

CREATE INDEX dokument_del_relation_idx_rel_maal_uuid
    ON dokument_del_relation
    USING btree
    (rel_type, rel_maal_uuid);

CREATE INDEX dokument_del_relation_idx_rel_maal_uuid_isolated
    ON dokument_del_relation
    USING btree
    (rel_maal_uuid);

CREATE INDEX dokument_del_relation_idx_rel_maal_urn_isolated
    ON dokument_del_relation
    USING btree
    (rel_maal_urn);

CREATE INDEX dokument_del_relation_idx_rel_maal_urn
    ON dokument_del_relation
    USING btree
    (rel_type, rel_maal_urn);

CREATE INDEX dokument_del_relation_idx_virkning_aktoerref
    ON dokument_del_relation
    USING btree
    (((virkning).aktoerref));

CREATE INDEX dokument_del_relation_idx_virkning_aktoertypekode
    ON dokument_del_relation
    USING btree
    (((virkning).aktoertypekode));

CREATE INDEX dokument_del_relation_idx_virkning_notetekst
    ON dokument_del_relation
    USING btree
    (((virkning).notetekst));

CREATE INDEX dokument_del_relation_pat_virkning_notetekst
    ON dokument_del_relation
    USING gin
    (((virkning).notetekst) gin_trgm_ops);
{% endif %}
{% endblock %}
