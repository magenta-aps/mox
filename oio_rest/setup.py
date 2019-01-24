#!/usr/bin/env python
# encoding: utf-8

import os
import pathlib
import re

from setuptools import find_packages, setup


basedir = pathlib.Path(__file__).parent

version = (basedir / 'VERSION').read_text().strip()

# extract requirements for pip & setuptools
install_requires = (basedir / 'requirements.txt').read_text().splitlines()
tests_require = [
    l for l in (basedir / 'requirements-test.txt').read_text().splitlines()
    if not l.startswith('-r')
]

# setuptools doesn't handle external dependencies, yes
dependency_links = [
    l.split('@', 1)[1].strip()
    for l in install_requires + tests_require
    if '@' in l
]


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
        'oio_rest.db': [
            'sql/*/*.sql',
        ],
        'oio_rest': [
            "templates/html/*.html",
            "templates/xml/*.xml",
            "test_auth_data/idp-certificate.pem",
        ],
    },
    python_requires='>=3.5',
    install_requires=install_requires,
    extras_require={
        'tests': tests_require,
    },
    tests_require=tests_require,
    include_package_data=True,
    zip_safe=False,

    entry_points={
        # -*- Entry points: -*-
        'console_scripts': [
            'mox = oio_rest.__main__:cli',
        ],
    },
    dependency_links=dependency_links,
)
