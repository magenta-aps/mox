#!/bin/sh

# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

set -e

DIR="$(cd $(dirname $0); pwd)"
VENV="$DIR/venv"

python3 -m venv "$VENV"

"$VENV/bin/python" -m pip -q install -r "$DIR/requirements.txt"
exec "$VENV/bin/python" -m sphinx.cmd.build "$@"
