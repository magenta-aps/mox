#!/usr/bin/env python
# Usage E.g: ./apply-template.py

import copy
import glob
import os
import subprocess

from collections import OrderedDict

import jinja2

from oio_rest.db_structure import DATABASE_STRUCTURE
from oio_rest.db_structure import DB_TEMPLATE_EXTRA_OPTIONS


DIR = os.path.realpath(os.path.join(
    os.path.dirname(__file__), '..', 'db', 'db-templating'),
)

TEMPLATES = (
    'dbtyper-specific',
    'tbls-specific',
    '_as_get_prev_registrering',
    '_as_create_registrering',
    'as_update',
    'as_create_or_import',
    'as_list',
    'as_read',
    'as_search',
    '_remove_nulls_in_array',
    'json-cast-functions',
    '_as_filter_unauth'
)

templateLoader = jinja2.FileSystemLoader(
    searchpath=os.path.join(DIR, "templates"),
)
templateEnv = jinja2.Environment(loader=templateLoader)

for oiotype in sorted(DATABASE_STRUCTURE):
    for template_name in sorted(TEMPLATES):
        TEMPLATE_FILE = template_name + '.jinja.sql'

        template = templateEnv.get_template(TEMPLATE_FILE)
        templateVars = copy.deepcopy(DATABASE_STRUCTURE[oiotype])
        templateVars["script_signature"] = (
            "apply-template.py " + oiotype + " " + TEMPLATE_FILE
        )
        # it is important that the order is stable, as some templates
        # rely on this
        templateVars['tilstande'] = OrderedDict(templateVars['tilstande'])
        # it is important that the order is stable, as some templates
        # rely on this
        templateVars['attributter'] = OrderedDict(templateVars['attributter'])
        templateVars['oio_type'] = oiotype.lower()

        # create version of 'tilstande' and 'attributter' in reverse order
        tilstande_items = list(templateVars['tilstande'].items())
        attributter_items = list(templateVars['attributter'].items())
        tilstande_items.reverse()
        attributter_items.reverse()
        templateVars['tilstande_revorder'] = OrderedDict(tilstande_items)
        templateVars['attributter_revorder'] = OrderedDict(attributter_items)

        if (
            oiotype in DB_TEMPLATE_EXTRA_OPTIONS and
            TEMPLATE_FILE in DB_TEMPLATE_EXTRA_OPTIONS[oiotype] and
            'include_mixin' in
                DB_TEMPLATE_EXTRA_OPTIONS[oiotype][TEMPLATE_FILE]
        ):
            templateVars['include_mixin'] = (
                DB_TEMPLATE_EXTRA_OPTIONS[oiotype]
                [TEMPLATE_FILE]['include_mixin']
            )
        else:
            templateVars['include_mixin'] = "empty.jinja"

        outputPath = os.path.join(DIR, 'generated-files',
                                  '{}_{}.sql'.format(template_name, oiotype))

        with open(outputPath, 'wb') as fp:
            template.stream(templateVars).dump(fp, encoding='utf-8')
            fp.write(b'\n')


for patch in glob.glob(os.path.join(DIR, 'patches', '*.diff')):
    subprocess.check_call(
        ['patch', '--fuzz=3', '-i', patch],
        cwd=os.path.join(DIR, 'generated-files'),
    )
