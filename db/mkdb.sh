#!/bin/bash
set -e

DIR=$( cd "$( dirname "$0" )" && pwd )
MOXDIR=$(cd $DIR/..; pwd)

if test -z "$TESTING"
then
    cat <<EOF
CREATE USER $MOX_DB_USER  WITH PASSWORD '$MOX_DB_PASSWORD';
CREATE DATABASE $MOX_DB WITH OWNER $MOX_DB_PASSWORD;
CREATE SCHEMA actual_state AUTHORIZATION $MOX_DB_USER;

ALTER DATABASE $MOX_DB SET search_path TO actual_state,public;

ALTER DATABASE $MOX_DB SET DATESTYLE to 'ISO, YMD';

ALTER DATABASE $MOX_DB SET INTERVALSTYLE to 'sql_standard';
EOF

    cat $DIR/basis/dbserver_prep.sql
    cat $DIR/basis/common_types.sql

    cat <<EOF
\c $MOX_DB
EOF
else
    cat <<EOF
CREATE SCHEMA actual_state AUTHORIZATION $MOX_DB_USER;

ALTER DATABASE $MOX_DB SET search_path TO actual_state,public;

ALTER DATABASE $MOX_DB SET DATESTYLE to 'ISO, YMD';

ALTER DATABASE $MOX_DB SET INTERVALSTYLE to 'sql_standard';

EOF

    cat $DIR/basis/common_types.sql
    cat <<EOF
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

EOF
fi

cat $DIR/funcs/_index_helper_funcs.sql
cat $DIR/funcs/_subtract_tstzrange.sql
cat $DIR/funcs/_subtract_tstzrange_arr.sql
cat $DIR/funcs/_as_valid_registrering_livscyklus_transition.sql
cat $DIR/funcs/_as_search_match_array.sql
cat $DIR/funcs/_as_search_ilike_array.sql
cat $DIR/funcs/_json_object_delete_keys.sql
cat $DIR/funcs/_create_notify.sql

$PYTHON "$DIR/../oio_rest/apply-templates.py" 1>&2

oiotypes=$($PYTHON -m oio_common.db_structure)

templates1=( dbtyper-specific tbls-specific _remove_nulls_in_array )


for oiotype in $oiotypes
do

	for template in "${templates1[@]}"
	do
		cat $DIR/db-templating/generated-files/${template}_${oiotype}.sql
	done
done


#Extra functions depending on templated data types 
cat $DIR/funcs/_ensure_document_del_exists_and_get.sql
cat $DIR/funcs/_ensure_document_variant_exists_and_get.sql
cat $DIR/funcs/_ensure_document_variant_and_del_exists_and_get_del.sql
cat $DIR/funcs/_as_list_dokument_varianter.sql


templates2=(  _as_get_prev_registrering _as_create_registrering as_update  as_create_or_import  as_list as_read as_search json-cast-functions _as_sorted _as_filter_unauth )


for oiotype in $oiotypes
do
	for template in "${templates2[@]}"
	do
		cat $DIR/db-templating/generated-files/${template}_${oiotype}.sql
	done
done
