#!/bin/bash
oiotypes=( facet klassifikation )
templates=( dbtyper-specific tbls-specific _as_get_prev_registrering _as_create_registrering as_update  as_create_or_import  as_list as_read as_search )


for oiotype in "${oiotypes[@]}"
do
	for template in "${templates[@]}"
	do
		PYTHONIOENCODING=UTF-8 ./apply-template.py ${oiotype} ${template}.jinja.sql >generated-files/${template}_${oiotype}.sql
	done	
done

