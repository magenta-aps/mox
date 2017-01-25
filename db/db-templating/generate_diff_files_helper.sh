#!/bin/bash
#REMEMBER TO RUN ON UNPATCHED GENERATED FILES!!
#That is, remember to temporarily deactivate patching of the specific OIO type in recreatedb.sh

diff --context=5 ./generated-files/tbls-specific_aktivitet.sql ./patches/tbls-specific_aktivitet.org.sql >patches/tbls-specific_aktivitet.sql.diff
diff --context=5 ./generated-files/dbtyper-specific_aktivitet.sql ./patches/dbtyper-specific_aktivitet.org.sql >patches/dbtyper-specific_aktivitet.sql.diff
diff --context=5 ./generated-files/_remove_nulls_in_array_aktivitet.sql patches/_remove_nulls_in_array_aktivitet.org.sql > patches/_remove_nulls_in_array_aktivitet.sql.diff 
diff --context=5 ./generated-files/json-cast-functions_aktivitet.sql ./patches/json-cast-functions_aktivitet.org.sql >patches/json-cast-functions_aktivitet.sql.diff 

diff --context=5 ./generated-files/as_search_aktivitet.sql ./patches/as_search_aktivitet.org.sql  > patches/as_search_aktivitet.sql.diff
diff --context=5 ./generated-files/as_create_or_import_aktivitet.sql ./patches/as_create_or_import_aktivitet.org.sql  > patches/as_create_or_import_aktivitet.sql.diff 
diff --context=5 ./generated-files/as_update_aktivitet.sql ./patches/as_update_aktivitet.org.sql  > patches/as_update_aktivitet.sql.diff 
diff --context=5 ./generated-files/as_list_aktivitet.sql ./patches/as_list_aktivitet.org.sql  > patches/as_list_aktivitet.sql.diff 
