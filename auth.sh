#!/bin/sh -e
# Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


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
