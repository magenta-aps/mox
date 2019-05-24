#!/bin/sh
set -e


# Setup env variables
# -------------------
# There are many env variable naming schemes used for database configuration.
#
# DB_* and DATABASE is used by oio_rest/settings.py.
# PG* is used by psql.
# POSTGRES_* is used by the official postgres docker image and is not supported.
#
# This docker image only support DB_* and DATABASE used by oio_rest/settings.py.

# We set the same defaults as in oio_rest/settings.py.
export DB_HOST=${DB_HOST-localhost}
export DB_PORT=${DB_PORT-5432}
export DB_USER=${DB_USER-mox}
export DB_PASSWORD=${DB_PASSWORD-mox}
export DATABASE=${DATABASE-mox}

# For pgsql. These are only used in this script.
# https://www.postgresql.org/docs/9.6/libpq-envars.html
export PGHOST=$DB_HOST
export PGPORT=$DB_PORT
export PGUSER=$DB_USER
export PGPASSWORD=$DB_PASSWORD



# Check if db is ready
# --------------------
# We check if postgres is ready to accept connections before optionally
# initializing the database and then starting the server.
until psql -c '\l'; do
    >&2 echo "Postgres is unavailable - sleeping"
    sleep 1
done

>&2 echo "Postgres is up - continuing"



# Initialize the database
# -----------------------
# We check if the actual_state schema exists, if not then initialize the
# database. actual_state is not special, it is just the first thing to be
# initialized.
if ! psql -t -c '\dn actual_state' | grep -q .; then
    echo "Initializing database"
    python3 -m oio_rest initdb
fi

# Exec the docker CMD
# -------------------
exec "$@"
