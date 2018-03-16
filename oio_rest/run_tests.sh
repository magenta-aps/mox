#!/bin/bash

set -e

cd $(dirname $0)

if [[ ! -e oio_rest/settings.py ]]; then
    NO_SETTINGS=true
    cp oio_rest/settings.py.base oio_rest/settings.py
fi

python -m virtualenv --quiet venv

. ./venv/bin/activate

python -m pip install -e '.[tests]'
python -m flake8 --exit-zero

./setup.py test

if [[ "$NO_SETTINGS" = true ]]; then
    rm oio_rest/settings.py
fi
