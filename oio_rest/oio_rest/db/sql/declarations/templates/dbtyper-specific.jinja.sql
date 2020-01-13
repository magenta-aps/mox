{% extends "basis.jinja.sql" %}
-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0
{% block body %}
--create custom type sans db-ids to be able to do "clean" function signatures "for the outside world".

{% for tilstand, tilstand_values in tilstande.items() %}CREATE TYPE {{oio_type|title}}{{tilstand|title}}Tils AS ENUM ({% for enum_val in tilstand_values %}'{{enum_val}}',{% endfor %}''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE {{oio_type|title}}{{tilstand|title}}TilsType AS (
    virkning Virkning,
    {{tilstand}} {{oio_type|title}}{{tilstand|title}}Tils
)
;
{% endfor %}

{% if oio_type == 'klasse' %}
CREATE TYPE KlasseSoegeordType AS (
soegeordidentifikator text,
beskrivelse text,
soegeordskategori text
)
;
{% endif %}

{%-for attribut , attribut_fields in attributter.items() %}
CREATE TYPE {{oio_type|title}}{{attribut|title}}AttrType AS (
{%- for field in attribut_fields %}
{%- if attributter_metadata[attribut][field]['type'] is defined %} 
{%- if attributter_metadata[attribut][field]['type'] =='int' or attributter_metadata[attribut][field]['type'] =='date' or attributter_metadata[attribut][field]['type']=='boolean' or attributter_metadata[attribut][field]['type']=='timestamptz' %}
{{field}} Clearable{{attributter_metadata[attribut][field]['type']|title}},
{% elif attributter_metadata[attribut][field]['type'] == 'interval(0)' %}
{{field}} ClearableInterval,
{%- else %}
{{field}} {{attributter_metadata[attribut][field]['type']}}, 
{%-endif %}
{%- else %}
{{field}} text,
{%-endif %}

{%- endfor %}
{% if oio_type == 'klasse' %}
soegeord KlasseSoegeordType[],
{% endif %}
 virkning Virkning
);
{% endfor %}

{% if oio_type == 'tilstand' %}
CREATE TYPE TilstandVaerdiRelationAttrType AS (
  forventet boolean,
  nominelVaerdi text
);
{% endif %}

CREATE TYPE {{oio_type|title}}RelationKode AS ENUM  ({% for relation in relationer_nul_til_en|list + relationer_nul_til_mange|list %}'{{relation}}'{% if not loop.last %},{% endif %}{% endfor %});  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _as_convert_{{oio_type}}_relation_kode_to_txt is invoked.

{% if oio_type == 'aktivitet' %}
CREATE TYPE AktivitetAktoerAttrObligatoriskKode AS ENUM ('noedvendig','valgfri');

CREATE TYPE AktivitetAktoerAttrAccepteretKode AS ENUM ('accepteret','foreloebigt','afslaaet');

CREATE TYPE AktivitetAktoerAttr AS (
  obligatorisk AktivitetAktoerAttrObligatoriskKode,
  accepteret AktivitetAktoerAttrAccepteretKode,
  repraesentation_uuid uuid,
  repraesentation_urn text 
);
{% elif oio_type == 'sag' %}
CREATE TYPE SagRelationJournalPostSpecifikKode AS ENUM ('journalnotat','vedlagtdokument','tilakteretdokument');
 
CREATE TYPE JournalNotatType AS (
titel text,
notat text,
format text
);

CREATE TYPE JournalPostDokumentAttrType AS (
dokumenttitel text,
offentlighedUndtaget OffentlighedundtagetType
);
{% endif %}

CREATE TYPE {{oio_type|title}}RelationType AS (
  relType {{oio_type|title}}RelationKode,
  virkning Virkning,
  uuid uuid,
  urn text,
  objektType text{% if oio_type == 'aktivitet' %},
  indeks int,
  aktoerAttr AktivitetAktoerAttr{% elif oio_type == 'indsats' %},
indeks int{% elif oio_type == 'sag' %},
  indeks int,
  relTypeSpec SagRelationJournalPostSpecifikKode,
  journalNotat JournalNotatType,
  journalDokumentAttr JournalPostDokumentAttrType{% elif oio_type == 'tilstand' %},
  indeks int,
  tilstandsVaerdiAttr TilstandVaerdiRelationAttrType
{% endif %}
)
;

{% if oio_type == 'dokument' %}
/**************************************************/
/*					DokumentDel                   */
/**************************************************/

CREATE TYPE DokumentdelRelationKode AS ENUM  ('underredigeringaf');  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _as_convert_dokumentdel_relation_kode_to_txt is invoked.


CREATE TYPE DokumentDelEgenskaberType AS (
indeks ClearableInt,
indhold text,
lokation text,
mimetype text,
 virkning Virkning
);


CREATE TYPE DokumentdelRelationType AS (
  relType DokumentdelRelationKode,
  virkning Virkning,
  uuid uuid,
  urn text,
  objektType text 
)
;

CREATE TYPE DokumentDelType AS
(
  deltekst text,
  egenskaber DokumentDelEgenskaberType[],
  relationer DokumentdelRelationType[]
);  



/**************************************************/
/*					Dokumentvariant               */
/**************************************************/

CREATE TYPE DokumentVariantEgenskaberType AS (
arkivering ClearableBoolean, 
delvisscannet ClearableBoolean, 
offentliggoerelse ClearableBoolean, 
produktion ClearableBoolean,
 virkning Virkning
);


CREATE TYPE DokumentVariantType AS
(
  varianttekst text,
  egenskaber DokumentVariantEgenskaberType[],
  dele DokumentDelType[]
);  

/**************************************************/
{% endif %}

CREATE TYPE {{oio_type|title}}RegistreringType AS
(
registrering RegistreringBase,
{%- for tilstand, tilstand_values in tilstande.items() %}
tils{{tilstand|title}} {{oio_type|title}}{{tilstand|title}}TilsType[],{% endfor %}
{%-for attribut , attribut_fields in attributter.items() %}
attr{{attribut|title}} {{oio_type|title}}{{attribut|title}}AttrType[],{% endfor %}
relationer {{oio_type|title}}RelationType[]{% if oio_type == 'dokument' %},
varianter DokumentVariantType[]{% endif %}
);

CREATE TYPE {{oio_type|title}}Type AS
(
  id uuid,
  registrering {{oio_type|title}}RegistreringType[]
);  

{% if oio_type == 'aktivitet' %}
 CREATE Type _AktivitetRelationMaxIndex AS
 (
   relType AktivitetRelationKode,
   indeks int
 );

---we'll add two small functions here, that will help with placing CHECK CONSTRAINT on the composite type AktivitetAktoerAttr in the db-table.
CREATE OR REPLACE FUNCTION _aktivitet_aktoer_attr_repr_uuid_to_text(AktivitetAktoerAttr) RETURNS TEXT AS 'SELECT $1.repraesentation_uuid::TEXT' LANGUAGE sql IMMUTABLE;
CREATE OR REPLACE FUNCTION _aktivitet_aktoer_attr_repr_urn_to_text(AktivitetAktoerAttr) RETURNS TEXT AS 'SELECT NULLIF($1.repraesentation_urn::TEXT,'''') ' LANGUAGE sql IMMUTABLE;
{% elif oio_type == 'dokument' %}
CREATE TYPE _DokumentVariantDelKey AS
(
  varianttekst text,
  deltekst text
);
{% elif oio_type == 'indsats' %}
 CREATE Type _IndsatsRelationMaxIndex AS
 (
   relType IndsatsRelationKode,
   indeks int
 );
{% elif oio_type == 'sag' %}
CREATE Type _SagRelationMaxIndex AS
(
  relType SagRelationKode,
  indeks int
);
{% elif oio_type == 'tilstand' %}
 CREATE Type _TilstandRelationMaxIndex AS
 (
   relType TilstandRelationKode,
   indeks int
 );
{% endif %}


{% endblock %}
