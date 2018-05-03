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

-- Please notice that the db-tests are run, using a different datestyle
ALTER DATABASE $MOX_DB SET DATESTYLE to 'ISO, YMD';

ALTER DATABASE $MOX_DB SET INTERVALSTYLE to 'sql_standard';
EOF

    cat $DIR/funcs/_amqp_functions.sql
    cat $DIR/basis/dbserver_prep.sql
    cat $DIR/basis/common_types.sql

    cat <<EOF
\c $MOX_DB

-- Setup AMQP server settings
INSERT into amqp.broker
(host, port, vhost, username, password)
values (
    '$MOX_AMQP_HOST', $MOX_AMQP_PORT, '$MOX_AMQP_VHOST', '$MOX_AMQP_USER',
    '$MOX_AMQP_PASS'
);

-- Grant mox user privileges to publish to AMQP
GRANT SELECT ON ALL TABLES IN SCHEMA amqp TO $MOX_DB_USER;

-- Declare AMQP MOX notifications exchange as type fanout
SELECT amqp.exchange_declare(1, 'mox.notifications', 'fanout', false, true, false);
EOF
else
    cat <<EOF
CREATE SCHEMA actual_state AUTHORIZATION $MOX_DB_USER;

ALTER DATABASE $MOX_DB SET search_path TO actual_state,public;

-- Please notice that the db-tests are run, using a different datestyle
ALTER DATABASE $MOX_DB SET DATESTYLE to 'ISO, YMD';

ALTER DATABASE $MOX_DB SET INTERVALSTYLE to 'sql_standard';

EOF

    cat $DIR/basis/common_types.sql
    cat <<EOF
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

CREATE OR REPLACE FUNCTION actual_state._amqp_publish_notification
(objekttype varchar, livscykluskode LivscyklusKode, objekt_uuid uuid)
RETURNS bool
AS
\$\$
SELECT TRUE;
\$\$ LANGUAGE sql immutable;
EOF
fi

cat $DIR/funcs/_index_helper_funcs.sql
cat $DIR/funcs/_subtract_tstzrange.sql
cat $DIR/funcs/_subtract_tstzrange_arr.sql
cat $DIR/funcs/_as_valid_registrering_livscyklus_transition.sql
cat $DIR/funcs/_as_search_match_array.sql
cat $DIR/funcs/_as_search_ilike_array.sql
cat $DIR/funcs/_json_object_delete_keys.sql

oiotypes=$($PYTHON -m oio_rest_lib.db_structure)

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


templates2=(  _as_get_prev_registrering _as_create_registrering as_update  as_create_or_import  as_list as_read as_search json-cast-functions _as_filter_unauth )


for oiotype in $oiotypes
do
	for template in "${templates2[@]}"
	do
		cat $DIR/db-templating/generated-files/${template}_${oiotype}.sql
	done
done
