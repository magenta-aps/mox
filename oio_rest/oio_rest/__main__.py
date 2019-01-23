# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import click
import flask.cli

from . import app
from .db import db_templating


@click.group(cls=flask.cli.FlaskGroup, create_app=lambda: app.app)
def cli():
    """Management script for OIO REST."""


@cli.command()
@click.option('-o', '--output', type=click.File('wt'), default='-')
def sql(output):
    '''Write database SQL structure to standard output'''

    for line in db_templating.get_sql():
        output.write(line)
        output.write('\n')


if __name__ == '__main__':
    cli()
