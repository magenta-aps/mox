#!/bin/bash -e

# TODO: Maybe make this directory a Python package & do the installation
# through setup.py.


virtualenv python-env
source python-env/bin/activate

pushd ../oio_rest
python setup.py sdist

pip install dist/oio_rest*.tar.gz
rm -rf dist/
popd

pip install pika
pip install requests


