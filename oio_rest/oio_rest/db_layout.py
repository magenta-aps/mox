#!/usr/bin/env python3
"""
    apply-templates.py
    ~~~~~~~~~~~~~~~~~~

    This script generates a bunch of sql files from jinja2 templates.

    More information in `../db/db-templating/`.

    Example usage:
        $ ./apply-template.py  # from a Python 3 environment
"""

from collections import OrderedDict
from pathlib import Path
import copy
import importlib

from jinja2 import Environment, FileSystemLoader

import settings

DB_DIR = Path(__file__).absolute().parent.parent.parent / "db"
TEMPLATE_DIR = DB_DIR / "db-templating" / "templates"

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


def render_templates(module_name):
    structmod = importlib.import_module(module_name)

    template_env = Environment(loader=FileSystemLoader([str(TEMPLATE_DIR)]))

    for oio_type in sorted(structmod.DATABASE_STRUCTURE):
        for template_name in TEMPLATES:
            template_file = "%s.jinja.sql" % template_name
            template = template_env.get_template(template_file)

            context = copy.deepcopy(structmod.DATABASE_STRUCTURE[oio_type])
            context["script_signature"] = "apply-template.py %s %s" % (
                oio_type,
                template_file,
            )
            # it is important that the order is stable, as some templates rely on this
            context["tilstande"] = OrderedDict(context["tilstande"])
            context["attributter"] = OrderedDict(context["attributter"])
            context["oio_type"] = oio_type.lower()

            try:
                context["include_mixin"] = (
                    structmod.DB_TEMPLATE_EXTRA_OPTIONS
                    [oio_type][template_file]["include_mixin"]
                )
            except KeyError:
                context["include_mixin"] = "empty.jinja"

            yield template.render(context)


def get_sql():
    yield 'CREATE SCHEMA actual_state AUTHORIZATION {user};'.format(
        user=settings.DB_USER,
    )
    yield '''
    ALTER database {db} SET search_path TO actual_state, public;
    ALTER database {db} SET DATESTYLE to 'ISO, YMD';
    ALTER database {db} SET INTERVALSTYLE to 'sql_standard';
    '''.format(db=settings.DATABASE)

    for dirp in (
        DB_DIR / "basis",
        DB_DIR / "funcs" / "pre",
        None,  # placeholder: put the templates here
        DB_DIR / "funcs" / "post",
    ):
        if dirp is None:
            yield from render_templates(settings.DB_STRUCTURE_MODULE)
        else:
            for p in dirp.glob('*.sql'):
                yield p.read_text()


if __name__ == '__main__':
    print('\n'.join(get_sql()))
