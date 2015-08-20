#!/bin/bash
#Please notice only invoke this file to refresh the .org files in the patches folder, if all patches has been succesfully applied.
#If you are unsure want this means, you probraly don't want to run this script.


cp ../generated-files/tbls-specific_klasse.sql ./tbls-specific_klasse.org.sql
cp ../generated-files/as_create_or_import_klasse.sql ./as_create_or_import_klasse.org.sql
cp ../generated-files/as_list_klasse.sql ./as_list_klasse.org.sql 
cp ../generated-files/as_search_klasse.sql ./as_search_klasse.org.sql
cp ../generated-files/as_update_klasse.sql ./as_update_klasse.org.sql
cp ../generated-files/_remove_nulls_in_array_klasse.sql ./_remove_nulls_in_array_klasse.org.sql
cp ../generated-files/tbls-specific_sag.sql ./tbls-specific_sag.org.sql
cp ../generated-files/dbtyper-specific_sag.sql ./dbtyper-specific_sag.org.sql
cp ../generated-files/as_list_sag.sql ./as_list_sag.org.sql
cp ../generated-files/_remove_nulls_in_array_sag.sql ./_remove_nulls_in_array_sag.org.sql
cp ../generated-files/as_create_or_import_sag.sql ./as_create_or_import_sag.org.sql
cp ../generated-files/as_update_sag.sql ./as_update_sag.org.sql
cp ../generated-files/json-cast-functions_sag.sql ./json-cast-functions_sag.org.sql
cp ../generated-files/as_search_sag.sql ./as_search_sag.org.sql
cp ../generated-files/dbtyper-specific_dokument.sql ./dbtyper-specific_dokument.org.sql
cp ../generated-files/tbls-specific_dokument.sql ./tbls-specific_dokument.org.sql
cp ../generated-files/as_create_or_import_dokument.sql ./as_create_or_import_dokument.org.sql
cp ../generated-files/as_update_dokument.sql ./as_update_dokument.org.sql
cp ../generated-files/_remove_nulls_in_array_dokument.sql ./_remove_nulls_in_array_dokument.org.sql
cp ../generated-files/as_list_dokument.sql ./as_list_dokument.org.sql
cp ../generated-files/json-cast-functions_dokument.sql ./json-cast-functions_dokument.org.sql
cp ../generated-files/as_search_dokument.sql ./as_search_dokument.org.sql
