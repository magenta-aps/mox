#!/bin/bash -e

# TODO: Maybe make this directory a Python package & do the installation
# through setup.py.


virtualenv python-env
source python-env/bin/activate
sed  "s#%PYTHON%#${PWD}/python-env/bin/python#" mox_advis.in.py > mox_advis.py
chmod +x mox_advis.py

sed  "s#%PYTHON%#${PWD}/python-env/bin/python#" mox_elk_log.in.py > mox_elk_log.py
chmod +x mox_elk_log.py

pushd ../oio_rest
python setup.py sdist

pip install dist/oio_rest*.tar.gz
rm -rf dist/
popd

pip install pika
pip install requests

sed "s#%PATH%#${PWD}#" setup/mox-advis.in.conf > setup/mox-advis.conf
sed "s#%PATH%#${PWD}#" setup/mox-elk-log.in.conf > setup/mox-elk-log.conf

sudo cp setup/mox-advis.conf /etc/init
sudo cp setup/mox-elk-log.conf /etc/init

rm setup/mox-advis.conf setup/mox-elk-log.conf

sudo initctl reload-configuration
