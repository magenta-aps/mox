#!/bin/bash

set -ex

cd $(dirname $0)

if [[ ! -e oio_rest/settings.py ]]; then
    NO_SETTINGS=true
    cp oio_rest/settings.py.base oio_rest/settings.py
fi

python -m virtualenv --quiet venv

. ./venv/bin/activate

python -m pip install -r requirements.txt -r requirements-test.txt
python -m flake8 --exit-zero
python -m pytest

if [[ "$NO_SETTINGS" = true ]]; then
    rm oio_rest/settings.py
fi
