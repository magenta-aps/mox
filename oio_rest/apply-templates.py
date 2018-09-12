#!/usr/bin/env python
"""
    apply-templates.py
    ~~~~~~~~~~~~~~~~~~

    This script generates a bunch of sql files from jinja2 templates.

    More information in `../db/db-templating/`.

    Example usage:
        $ ./apply-template.py  # from a Python 3 environment
"""

from collections import OrderedDict
import copy
from pathlib import Path

from jinja2 import Environment, FileSystemLoader

from oio_common.db_structure import DATABASE_STRUCTURE
from oio_common.db_structure import DB_TEMPLATE_EXTRA_OPTIONS


TEMPLATE_DIR = Path("../db/db-templating/templates")
BUILD_DIR = Path("../db/db-templating/generated-files")

TEMPLATES = (
    "_as_create_registrering",
    "_as_filter_unauth",
    "_as_get_prev_registrering",
    "_remove_nulls_in_array",
    "as_create_or_import",
    "as_list",
    "as_read",
    "as_search",
    "as_update",
    "dbtyper-specific",
    "json-cast-functions",
    "tbls-specific",
)

template_env = Environment(loader=FileSystemLoader([TEMPLATE_DIR]))

for oio_type in sorted(DATABASE_STRUCTURE):
    for template_name in sorted(TEMPLATES):
        template_file = "%s.jinja.sql" % template_name
        template = template_env.get_template(template_file)

        context = copy.deepcopy(DATABASE_STRUCTURE[oio_type])
        context["script_signature"] = "apply-template.py %s %s" % (
            oio_type,
            template_file,
        )
        # it is important that the order is stable, as some templates rely on this
        context["tilstande"] = OrderedDict(context["tilstande"])
        context["attributter"] = OrderedDict(context["attributter"])
        context["oio_type"] = oio_type.lower()
        # create version of 'tilstande' and 'attributter' in reverse order
        context["tilstande_revorder"] = OrderedDict(
            reversed(context["tilstande"].items())
        )
        context["attributter_revorder"] = OrderedDict(
            reversed(context["attributter"].items())
        )

        try:
            context["include_mixin"] = DB_TEMPLATE_EXTRA_OPTIONS[oio_type][
                template_file
            ]["include_mixin"]
        except KeyError:
            context["include_mixin"] = "empty.jinja"

        generated_file = Path(BUILD_DIR, "%s_%s.sql" % (template_name, oio_type))
        with open(generated_file, "wb") as f:
            template.stream(context).dump(f, encoding="utf-8")
            f.write(b"\n")
