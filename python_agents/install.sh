#!/bin/bash -e

# TODO: Maybe make this directory a Python package & do the installation
# through setup.py.


virtualenv python-env
source python-env/bin/activate
sed  "s#PYTHON#${PWD}/python-env/bin/python#" mox_advis.in.py > mox_advis.py
chmod +x mox_advis.py

sed  "s#PYTHON#${PWD}/python-env/bin/python#" mox_elk_log.in.py > mox_elk_log.py
chmod +x mox_elk_log.py

pushd ../oio_rest
python setup.py sdist

pip install dist/oio_rest*.tar.gz
rm -rf dist/
popd

pip install pika
pip install requests

sudo cp setup/*.conf /etc/init
sudo initctl reload-configuration
