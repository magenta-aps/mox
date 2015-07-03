#!/bin/bash

source ./config.sh

sudo -u postgres dropdb $MOX_DB
sudo -u postgres createdb $MOX_DB
sudo -u postgres psql -c "GRANT ALL ON DATABASE $MOX_DB TO $MOX_USER"
sudo -u postgres psql -d $MOX_DB -f basis/dbserver_prep.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -c "CREATE SCHEMA actual_state AUTHORIZATION $MOX_USER "
sudo -u postgres psql -c "ALTER database $MOX_DB SET search_path TO actual_state,public;"
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -c "CREATE SCHEMA test AUTHORIZATION $MOX_USER "
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f basis/common_types.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f funcs/_index_helper_funcs.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f funcs/_subtract_tstzrange.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f funcs/_subtract_tstzrange_arr.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f funcs/_as_valid_registrering_livscyklus_transition.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f funcs/_as_search_match_array.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f funcs/_json_object_delete_keys.sql


cd ./db-templating/
./generate-sql-tbls-types-funcs-for-oiotype.sh

#Apply patches 
cd ./generated-files/
#klasse
patch --fuzz=3 -i  ../patches/dbtyper-specific_klasse.sql.diff
patch --fuzz=3 -i  ../patches/tbls-specific_klasse.sql.diff
patch --fuzz=3 -i  ../patches/as_create_or_import_klasse.sql.diff
patch --fuzz=3 -i  ../patches/as_list_klasse.sql.diff
patch --fuzz=3 -i  ../patches/as_search_klasse.sql.diff
patch --fuzz=3 -i  ../patches/as_update_klasse.sql.diff
patch --fuzz=3 -i  ../patches/_remove_nulls_in_array_klasse.sql.diff
#sag
patch --fuzz=3 -i  ../patches/tbls-specific_sag.sql.diff
patch --fuzz=3 -i  ../patches/dbtyper-specific_sag.sql.diff
patch --fuzz=3 -i  ../patches/as_list_sag.sql.diff
patch --fuzz=3 -i  ../patches/_remove_nulls_in_array_sag.sql.diff
patch --fuzz=3 -i  ../patches/as_create_or_import_sag.sql.diff
patch --fuzz=3 -i  ../patches/as_update_sag.sql.diff
patch --fuzz=3 -i  ../patches/json-cast-functions_sag.sql.diff 

cd ..

oiotypes=( facet klassifikation klasse bruger interessefaellesskab itsystem organisation organisationenhed organisationfunktion sag )
templates=( dbtyper-specific tbls-specific _remove_nulls_in_array _as_get_prev_registrering _as_create_registrering as_update  as_create_or_import  as_list as_read as_search json-cast-functions )


for oiotype in "${oiotypes[@]}"
do
	for template in "${templates[@]}"
	do
		sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f ./generated-files/${template}_${oiotype}.sql
	done	
done



cd ..

#Test functions
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_remove_nulls_in_array_klasse.sql

#Facet
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_facet_db_schama.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_create_or_import_facet.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_list_facet.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_read_facet.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_search_facet.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_update_facet.sql
#Klasse (BUT testing template-generated code through klasse, IM)
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_update_klasse.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_read_klasse.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_list_klasse.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_search_klasse.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_remove_nulls_in_array_klasse.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_search_match_array.sql
#itsystem
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_search_itsystem.sql
#sag
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_create_or_import_sag.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_update_sag.sql
#sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_sag_relation_type_to_json
