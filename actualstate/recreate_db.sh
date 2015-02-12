#!/bin/sh
sudo -u postgres dropdb mox
sudo -u postgres createdb mox
sudo -u postgres psql -d mox -f sql/common.sql
sudo -u postgres psql -d mox -f sql/base_tables.sql
sudo -u postgres psql -d mox -f sql/views.sql
python generate_tables.py | sudo -u postgres psql -d mox
sudo -u postgres psql -d mox -f sql/triggers.sql
sudo -u postgres psql -d mox -f sql/crud.sql
