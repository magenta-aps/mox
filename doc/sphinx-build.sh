#!/bin/sh

set -e

DIR="$(cd $(dirname $0; pwd))"
VENV="$DIR/venv"

python3 -m venv venv

./venv/bin/python -m pip -q install sphinx
exec ./venv/bin/python -m sphinx.cmd.build "$@"
