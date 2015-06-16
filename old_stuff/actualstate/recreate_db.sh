#!/bin/sh
sudo -u postgres dropdb mox
sudo -u postgres createdb mox
sudo -u postgres psql -c "GRANT ALL ON DATABASE mox TO mox"
sudo -u postgres psql -d mox -f sql/common.sql
psql -d mox -U mox -f sql/base_tables.sql
psql -d mox -U mox -f sql/views.sql
python generate_tables.py | psql -d mox -U mox
psql -d mox -U mox -f sql/triggers.sql
psql -d mox -U mox -f sql/crud.sql
