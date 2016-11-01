#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})

AS_USER="mox"

cd $DIR > /dev/null
if [[ `whoami` != "$AS_USER" ]]; then
    sudo su $AS_USER -c "source python-env/bin/activate && python moxwiki/app.py && deactivate"
else
    source python-env/bin/activate && python moxwiki/app.py && deactivate
fi
cd - > /dev/null

