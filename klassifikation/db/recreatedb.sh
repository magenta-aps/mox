#!/bin/bash
#Requires that a local mox user exist for peer auth against postgresql
sudo -u postgres dropdb mox
sudo -u postgres createdb mox
sudo -u postgres psql -c "GRANT ALL ON DATABASE mox TO mox"
sudo -u postgres psql -d mox -f tbls/dbserver_prep.sql
psql -d mox -U mox -c "CREATE SCHEMA actual_state AUTHORIZATION mox "
sudo -u postgres psql -c "ALTER database mox SET search_path TO actual_state,public;"
psql -d mox -U mox -c "CREATE SCHEMA test AUTHORIZATION mox "
psql -d mox -U mox -f tbls/common_types.sql
psql -d mox -U mox -f funcs/index_helper_funcs.sql
psql -d mox -U mox -f funcs/_subtract_tstzrange.sql
psql -d mox -U mox -f funcs/_subtract_tstzrange_arr.sql
psql -d mox -U mox -f funcs/_as_valid_registrering_livscyklus_transition.sql

cd ./db-templating/
./generate-sql-tbls-types-funcs-for-oiotype.sh

oiotypes=( facet klassifikation )
templates=( dbtyper-specific tbls-specific _as_get_prev_registrering _as_create_registrering as_update  as_create_or_import  as_list as_read as_search  )


for oiotype in "${oiotypes[@]}"
do
	for template in "${templates[@]}"
	do
		psql -d mox -U mox -f ./generated-files/${template}_${oiotype}.sql
	done	
done

cd ..

#Test functions

psql -d mox -U mox -f tests/test_facet_db_schama.sql
psql -d mox -U mox -f tests/test_as_create_or_import_facet.sql
psql -d mox -U mox -f tests/test_as_list_facet.sql
psql -d mox -U mox -f tests/test_as_read_facet.sql
psql -d mox -U mox -f tests/test_as_search_facet.sql
psql -d mox -U mox -f tests/test_as_update_facet.sql


