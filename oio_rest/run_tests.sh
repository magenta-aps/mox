#!/bin/bash

cd $(dirname $0)

if [[ ! -e oio_rest/settings.py ]]; then
    cp oio_rest/settings.py.base oio_rest/settings.py
fi

virtualenv -p python venv

venv/bin/python setup.py test
