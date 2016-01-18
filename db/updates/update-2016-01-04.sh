#!/bin/bash

source ../config.sh

templates=( json-cast-functions_bruger.sql json-cast-functions_dokument.sql json-cast-functions_facet.sql json-cast-functions_interessefaellesskab.sql json-cast-functions_itsystem.sql json-cast-functions_klasse.sql json-cast-functions_klassifikation.sql json-cast-functions_organisation.sql json-cast-functions_organisationenhed.sql json-cast-functions_organisationfunktion.sql json-cast-functions_sag.sql )

for template in "${templates[@]}"
do
	sudo -u postgres psql -d $MOX_DB -f ../db-templating/generated-files/${template}
done
