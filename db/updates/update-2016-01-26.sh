#!/usr/bin/env bash

echo "Do run this in MOX root directory"

psql -d mox -U mox -f db/funcs/_as_valid_registrering_livscyklus_transition.sql
