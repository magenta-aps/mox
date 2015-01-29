#!/bin/sh
sudo -u postgres psql -d mox -f sql/examples.sql
