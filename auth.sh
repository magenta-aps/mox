#!/bin/sh

MOXDIR=$(cd $(dirname $0); pwd)

export PYTHONPATH="$MOXDIR/oio_rest"

source "$MOXDIR/oio_rest/python-env-mac/bin/activate"

exec python -m oio_rest.auth.tokens "$@"
