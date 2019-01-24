# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


"""This module contains routines for generating the database from
Jinja2 templates.

"""

from collections import OrderedDict
from pathlib import Path
import copy
import importlib
import re

from jinja2 import Environment, FileSystemLoader

from .. import settings


DB_DIR = Path(__file__).parent / 'sql' / 'declarations'

template_env = Environment(loader=FileSystemLoader(str(DB_DIR)))

TEMPLATE_PATTERN = re.compile(r'^\d+-(?P<name>.*\.sql)$')


def _render_template(template_name, template_file):
    db_structure = settings.DB_STRUCTURE.DATABASE_STRUCTURE
    extra_options = settings.DB_STRUCTURE.DB_TEMPLATE_EXTRA_OPTIONS

    template = template_env.get_template(template_file)

    for oio_type in sorted(db_structure):
        context = copy.deepcopy(db_structure[oio_type])

        # it is important that the order is stable, as some templates rely on this
        context["tilstande"] = OrderedDict(context["tilstande"])
        context["attributter"] = OrderedDict(context["attributter"])

        context["oio_type"] = oio_type.lower()

        try:
            context["include_mixin"] = (
                extra_options[oio_type][template_name]["include_mixin"]
            )
        except KeyError:
            context["include_mixin"] = "empty.jinja.sql"

        yield template.render(context)


def get_sql():
    for p in sorted(DB_DIR.iterdir()):
        m = TEMPLATE_PATTERN.fullmatch(p.name)
        if not m:
            continue
        if p.stem.endswith('.jinja'):
            yield from _render_template(m.group('name'),
                                        str(p.relative_to(DB_DIR)))
        else:
            yield p.read_text()


if __name__ == '__main__':
    print('\n'.join(get_sql()))
