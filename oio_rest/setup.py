#!/usr/bin/env python
# encoding: utf-8

import os

from setuptools import find_packages, setup

basedir = os.path.dirname(__file__)

with open(os.path.join(basedir, 'VERSION')) as fp:
    version = fp.read().strip()

setup(
    name='oio_rest',
    version=version,
    description="Python and PostgreSQL implementation "
                "of the OIO service interfaces.",
    long_description="""\
    Implementation of various object hierarchies from the Danish Government's
    OIOXML standard for the exchange of public administration documents.""",
    classifiers=[],
    keywords='',
    author='Magenta ApS',
    author_email='info@magenta.dk',
    url='https://github.com/magenta-aps/mox',
    license='Mozilla Public License Version 2.0',
    packages=find_packages(exclude=['ez_setup', 'examples', 'tests']),
    package_data={
        '': ["*.txt", "*.xml", "*.pem"]
    },
    include_package_data=True,
    zip_safe=False,
    entry_points={
        # -*- Entry points: -*-
        'console_scripts': [
            'oio_api = oio_rest.app:app.run',
        ],
    },
)
