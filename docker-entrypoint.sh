#!/bin/sh
set -e

until PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -c '\l'; do
    >&2 echo "Postgres is unavailable - sleeping"
    sleep 1
done

>&2 echo "Postgres is up - continuing"

if ! PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -t -c '\dn actual_state' | grep -q .; then
    echo "Initializing database"
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -v ON_ERROR_STOP=1 <<EOF
CREATE SCHEMA actual_state AUTHORIZATION $POSTGRES_USER;
ALTER DATABASE mox SET search_path TO actual_state, public;
ALTER DATABASE mox SET DATESTYLE to 'ISO, YMD';
ALTER DATABASE mox SET INTERVALSTYLE to 'sql_standard';
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA actual_state;
CREATE EXTENSION IF NOT EXISTS "btree_gist" WITH SCHEMA actual_state;
CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA actual_state;
EOF
    python3 -m oio_rest sql | PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d mox -v ON_ERROR_STOP=1
fi

exec "$@"
