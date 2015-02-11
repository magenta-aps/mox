#!/bin/sh

sudo -u postgres pg_prove -d mox tests/crud.sql
