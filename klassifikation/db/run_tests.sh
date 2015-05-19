#!/bin/sh
#Requires that a local mox user exist for peer auth against postgresql
psql -d mox -U mox -c "SELECT * FROM runtests('test'::name);"