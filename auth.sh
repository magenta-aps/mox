#!/bin/sh -e
# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0


MOXDIR=$(cd $(dirname $0); pwd)

if test -z "$PYTHON"
then
    PYTHON=../python-env/bin/python
fi

# the script neither reads to nor writes from any file, so we can
# safely cd to a fixed location -- this fixes running this script from
# '$MOXDIR/oio_rest/oio_rest'
cd "$MOXDIR/oio_rest"

exec "$PYTHON" -s -m oio_rest.auth.tokens "$@"
