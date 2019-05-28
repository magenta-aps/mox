#!/bin/sh
set -e

python3 -m oio_rest initdb

exec "$@"
