#!/bin/sh -e

MOXDIR=$(cd $(dirname $0); pwd)

# the script neither reads to nor writes from any file, so we can
# safely cd to a fixed location -- this fixes running this script from
# '$MOXDIR/oio_rest/oio_rest'
cd "$MOXDIR/oio_rest"

exec python-env/bin/python -s -m oio_rest.auth.tokens "$@"
