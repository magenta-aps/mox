# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0


"""This module contains routines for generating the database from
Jinja2 templates.

"""

from collections import OrderedDict
from pathlib import Path
import copy

from jinja2 import Environment, FileSystemLoader

from oio_rest.db import db_structure


DB_DIR = Path(__file__).parent / "sql" / "declarations"

template_env = Environment(loader=FileSystemLoader(str(DB_DIR / "templates")))

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


def _render_templates():
    for oio_type in sorted(db_structure.DATABASE_STRUCTURE):
        for template_name in TEMPLATES:
            template_file = "%s.jinja.sql" % template_name
            template = template_env.get_template(template_file)

            context = copy.deepcopy(db_structure.DATABASE_STRUCTURE[oio_type])

            for reltype in ("tilstande", "attributter", "relationer"):
                if reltype not in context:
                    continue

                # it is important that the order is stable, as some templates
                # rely on this
                context[reltype] = OrderedDict(context[reltype])

                # fill these out to avoid the need to check for membership
                meta = context.get("{}_metadata".format(reltype), {})

                context["{}_metadata".format(reltype)] = {
                    a: {p: meta.get(a, {}).get(p, {}) for p in ps}
                    for a, ps in context["attributter"].items()
                }

                context["{}_mandatory".format(reltype)] = {
                    attr: [k for k, v in vs.items() if v.get("mandatory")]
                    for attr, vs in meta.items()
                }

            context["oio_type"] = oio_type.lower()

            try:
                extra_options = db_structure.DB_TEMPLATE_EXTRA_OPTIONS
                context["include_mixin"] = extra_options[oio_type][template_file][
                    "include_mixin"
                ]
            except KeyError:
                context["include_mixin"] = "empty.jinja.sql"

            yield template.render(context)


def get_sql():
    for dirp in (
        DB_DIR / "basis",
        DB_DIR / "pre-funcs",
        None,  # placeholder: put the templates here
        DB_DIR / "post-funcs",
    ):
        if dirp is None:
            yield from _render_templates()
        else:
            for p in sorted(dirp.glob("*.sql")):
                yield p.read_text()


if __name__ == "__main__":
    print("\n".join(get_sql()))
