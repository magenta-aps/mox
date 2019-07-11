#!/bin/sh
set -e

python3 -m oio_rest initdb --wait 30

exec "$@"
