#!/bin/sh
sudo apt-get -y install postgresql-contrib
sudo -u postgres dropdb mox
sudo -u postgres createdb mox
python generate_tables.py | sudo -u postgres psql -d mox
sudo -u postgres psql -d mox -f crud.sql
