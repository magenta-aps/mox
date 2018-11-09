#!/bin/bash -e
set -b

MOXDIR=${BASE_DIR}
DIR=${DB_DIR}

test -z "$DIR" && DIR=$(cd $(dirname $0); pwd)
test -z "$BASE_DIR" && BASE_DIR=$(cd $(dirname $DIR); pwd)
test -z "$PYTHON_EXEC" && PYTHON_EXEC=${BASE_DIR}/python-env/bin/python
test -z "$SUPER_USER" && SUPER_USER=postgres
test -z "$MOX_DB" && MOX_DB=mox
test -z "$MOX_DB_USER" && MOX_DB_USER=mox
test -z "$MOX_DB_PASSWORD" && MOX_DB_PASSWORD=mox

cd $DIR

PYTHON=${PYTHON_EXEC}

export PGPASSWORD="$MOX_DB_PASSWORD"
# TODO: Support remote $SUPER_USER DB server
#export PGHOST="$MOX_DB_HOST"

sudo -u postgres createdb $MOX_DB
sudo -u postgres createuser $MOX_DB_USER
sudo -u postgres psql -c "ALTER USER $MOX_DB_USER WITH PASSWORD '$MOX_DB_PASSWORD';"
sudo -u postgres psql -c "GRANT ALL ON DATABASE $MOX_DB TO $MOX_DB_USER"
sudo -u postgres psql -d $MOX_DB -f basis/dbserver_prep.sql

psql -d $MOX_DB -U $MOX_DB_USER -c "CREATE SCHEMA actual_state AUTHORIZATION $MOX_DB_USER "
sudo -u postgres psql -c "ALTER database $MOX_DB SET search_path TO actual_state,public;"
sudo -u postgres psql -c "ALTER database $MOX_DB SET DATESTYLE to 'ISO, YMD';" #Please notice that the db-tests are run, using a different datestyle
sudo -u postgres psql -c "ALTER database $MOX_DB SET INTERVALSTYLE to 'sql_standard';"

psql -d $MOX_DB -U $MOX_DB_USER -c "CREATE SCHEMA test AUTHORIZATION $MOX_DB_USER "
psql -d $MOX_DB -U $MOX_DB_USER -f basis/common_types.sql
psql -d $MOX_DB -U $MOX_DB_USER -f funcs/_index_helper_funcs.sql
psql -d $MOX_DB -U $MOX_DB_USER -f funcs/_subtract_tstzrange.sql
psql -d $MOX_DB -U $MOX_DB_USER -f funcs/_subtract_tstzrange_arr.sql
psql -d $MOX_DB -U $MOX_DB_USER -f funcs/_as_valid_registrering_livscyklus_transition.sql
psql -d $MOX_DB -U $MOX_DB_USER -f funcs/_as_search_match_array.sql
psql -d $MOX_DB -U $MOX_DB_USER -f funcs/_as_search_ilike_array.sql
psql -d $MOX_DB -U $MOX_DB_USER -f funcs/_json_object_delete_keys.sql
psql -d $MOX_DB -U $MOX_DB_USER -f funcs/_create_notify.sql

cd ./db-templating/
$PYTHON ../../oio_rest/apply-templates.py

oiotypes=$($PYTHON -m oio_common.db_structure)

templates1=( dbtyper-specific tbls-specific _remove_nulls_in_array )


for oiotype in $oiotypes
do
	for template in "${templates1[@]}"
	do
		psql -d $MOX_DB -U $MOX_DB_USER -f ./generated-files/${template}_${oiotype}.sql
	done	
done


#Extra functions depending on templated data types 
psql -d $MOX_DB -U $MOX_DB_USER -f ../funcs/_ensure_document_del_exists_and_get.sql
psql -d $MOX_DB -U $MOX_DB_USER -f ../funcs/_ensure_document_variant_exists_and_get.sql
psql -d $MOX_DB -U $MOX_DB_USER -f ../funcs/_ensure_document_variant_and_del_exists_and_get_del.sql
psql -d $MOX_DB -U $MOX_DB_USER -f ../funcs/_as_list_dokument_varianter.sql


templates2=(  _as_get_prev_registrering _as_create_registrering as_update  as_create_or_import  as_list as_read as_search json-cast-functions _as_sorted _as_filter_unauth )


for oiotype in $oiotypes
do
	for template in "${templates2[@]}"
	do
		psql -d $MOX_DB -U $MOX_DB_USER -f ./generated-files/${template}_${oiotype}.sql
	done	
done

cd ..


#Test functions
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_remove_nulls_in_array_klasse.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_common_types_cleable_casts.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_common_types_cleable_casts.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_search_match_array.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_search_ilike_array.sql
#Facet
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_facet_db_schama.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_create_or_import_facet.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_list_facet.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_read_facet.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_search_facet.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_update_facet.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_filter_unauth_facet.sql
#Klasse (BUT testing template-generated code through klasse, IM)
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_update_klasse.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_read_klasse.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_list_klasse.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_search_klasse.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_remove_nulls_in_array_klasse.sql

#itsystem
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_search_itsystem.sql
#sag
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_create_or_import_sag.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_update_sag.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_search_sag.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_json_object_delete_keys.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_json_cast_function.sql
#dokument
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_create_or_import_dokument.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_list_dokument.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_update_dokument.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_search_dokument.sql
#tilstand
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_create_or_import_tilstand.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_update_tilstand.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_search_tilstand.sql
#indsats
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_create_or_import_indsats.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_update_indsats.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_search_indsats.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_filter_unauth_indsats.sql
#aktivitet
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_create_or_import_aktivitet.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_update_aktivitet.sql
psql -d $MOX_DB -U $MOX_DB_USER -f tests/test_as_search_aktivitet.sql
