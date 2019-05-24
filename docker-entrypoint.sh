#!/bin/sh
set -e

# This docker image only supports DB_* and DATABASE used by
# ``oio_rest/settings.py``. We use the same defaults.
export DB_HOST=${DB_HOST-localhost}
export DB_PORT=${DB_PORT-5432}
export DB_USER=${DB_USER-mox}
export DB_PASSWORD=${DB_PASSWORD-mox}
export DATABASE=${DATABASE-mox}

python3 -m oio_rest initdb

exec "$@"
