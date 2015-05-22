#!/bin/bash
oiotypes=( facet klassifikation )
templates=( actual_state_update  actual_state_create_or_import _actual_state_create_registrering _actual_state_get_prev_registrering actual_state_list actual_state_read actual_state_search actual_state_update dbtyper-specific tbls-specific )


for oiotype in "${oiotypes[@]}"
do
	for template in "${templates[@]}"
	do
		PYTHONIOENCODING=UTF-8 ./apply-template.py ${oiotype} ${template}.jinja.sql >generated-files/${template}_${oiotype}.sql
	done	
done

