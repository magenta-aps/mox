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

from jinja2 import Environment, FileSystemLoader

from .. import settings


DB_DIR = Path(__file__).parent / 'sql' / 'declarations'

template_env = Environment(loader=FileSystemLoader(str(DB_DIR / 'templates')))

TEMPLATES = (
    "dbtyper-specific",
    "tbls-specific",
    "_remove_nulls_in_array",
    "_as_get_prev_registrering",
    "_as_create_registrering",
    "as_update",
    "as_create_or_import",
    "as_list",
    "as_read",
    "as_search",
    "json-cast-functions",
    "_as_sorted",
    "_as_filter_unauth",
)


def render_templates():
    db_structure = settings.DB_STRUCTURE.DATABASE_STRUCTURE
    extra_options = settings.DB_STRUCTURE.DB_TEMPLATE_EXTRA_OPTIONS

    for template_name in TEMPLATES:
        for oio_type in sorted(db_structure):
            template_file = "%s.jinja.sql" % template_name
            template = template_env.get_template(template_file)

            context = copy.deepcopy(db_structure[oio_type])

            # it is important that the order is stable, as some templates rely on this
            context["tilstande"] = OrderedDict(context["tilstande"])
            context["attributter"] = OrderedDict(context["attributter"])

            context["oio_type"] = oio_type.lower()

            try:
                context["include_mixin"] = (
                    extra_options[oio_type][template_file]["include_mixin"]
                )
            except KeyError:
                context["include_mixin"] = "empty.jinja.sql"

            yield '-- ' + template_file + '\n'  + template.render(context)


def get_sql():
    for dirp in (
        DB_DIR / "basis",
        DB_DIR / "pre-funcs",
        None,  # placeholder: put the templates here
        DB_DIR / "post-funcs",
    ):
        if dirp is None:
            yield from render_templates()
        else:
            for p in sorted(dirp.glob('*.sql')):
                yield '-- ' + p.name + '\n' + p.read_text()


if __name__ == '__main__':
    print('\n'.join(get_sql()))
