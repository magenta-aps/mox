#!/bin/bash -e

DIR=$(cd $(dirname $0); pwd)
MOXDIR=$(cd $DIR/../..; pwd)

PYTHON="$MOXDIR/python-env/bin/python"
export PYTHONIOENCODING=UTF-8

oiotypes=$($PYTHON -m oio_rest.db_helpers)

templates=( dbtyper-specific tbls-specific _as_get_prev_registrering _as_create_registrering as_update  as_create_or_import  as_list as_read as_search _remove_nulls_in_array json-cast-functions _as_filter_unauth )

cd $DIR

for oiotype in $oiotypes
do
	for template in "${templates[@]}"
	do
		$PYTHON ./apply-template.py ${oiotype} ${template}.jinja.sql >generated-files/${template}_${oiotype}.sql
	done	
done

