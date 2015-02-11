#!/bin/sh
sudo apt-get -y install postgresql-server-dev-9.3 pgxnclient
sudo pgxn install pgtap
sudo apt-get -y install postgresql-contrib
./recreate_db.sh
./run_tests.sh
