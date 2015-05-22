#!/bin/bash
#Requires that a local mox user exist for peer auth against postgresql
sudo -u postgres dropdb mox
sudo -u postgres createdb mox
sudo -u postgres psql -c "GRANT ALL ON DATABASE mox TO mox"
sudo -u postgres psql -d mox -f tbls/dbserver_prep.sql
psql -d mox -U mox -c "CREATE SCHEMA test AUTHORIZATION mox "
psql -d mox -U mox -f tbls/common_types.sql
psql -d mox -U mox -f funcs/index_helper_funcs.sql
psql -d mox -U mox -f funcs/subtract_tstzrange.sql
psql -d mox -U mox -f funcs/subtract_tstzrange_arr.sql
psql -d mox -U mox -f funcs/_actual_state_valid_registrering_livscyklus_transition.sql

cd ./db-templating/
./generate-sql-tbls-types-funcs-for-oiotype.sh

oiotypes=( facet klassifikation )
templates=( dbtyper-specific tbls-specific _actual_state_get_prev_registrering _actual_state_create_registrering actual_state_update  actual_state_create_or_import  actual_state_list actual_state_read actual_state_search   )


for oiotype in "${oiotypes[@]}"
do
	for template in "${templates[@]}"
	do
		psql -d mox -U mox -f ./generated-files/${template}_${oiotype}.sql
	done	
done

cd ..

#psql -d mox -U mox -f funcs/_actual_state_get_prev_facet_registrering.sql
#psql -d mox -U mox -f funcs/_actual_state_create_facet_registrering.sql

#psql -d mox -U mox -f funcs/actual_state_create_or_import_facet.sql
#psql -d mox -U mox -f funcs/actual_state_update_facet.sql
#psql -d mox -U mox -f funcs/actual_state_list_facet.sql
#psql -d mox -U mox -f funcs/actual_state_read_facet.sql
#psql -d mox -U mox -f funcs/actual_state_search_facet.sql

#Test functions

#psql -d mox -U mox -f tests/test_facet_db_schama.sql
#psql -d mox -U mox -f tests/test_actual_state_create_or_import_facet.sql
#psql -d mox -U mox -f tests/test_actual_state_list_facet.sql
#psql -d mox -U mox -f tests/test_actual_state_read_facet.sql
#psql -d mox -U mox -f tests/test_actual_state_search_facet.sql
#psql -d mox -U mox -f tests/test_actual_state_update_facet.sql


