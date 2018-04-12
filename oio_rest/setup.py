#!/usr/bin/env python2.7
# encoding: utf-8

import os

from setuptools import find_packages, setup

version = '0.0.1'
authors = 'C. Agger, Jørgen Ulrik B. Krag, Thomas Kristensen, Seth Yastrov'
basedir = os.path.dirname(__file__)

with open(os.path.join(basedir, 'requirements.txt')) as fp:
    install_requires = fp.readlines()

with open(os.path.join(basedir, 'requirements-test.txt')) as fp:
    test_requires = fp.readlines()

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
    author=authors,
    author_email='info@magenta.dk',
    url='https://github.com/magenta-aps/mox',
    license='Mozilla Public License Version 2.0',
    packages=find_packages(exclude=['ez_setup', 'examples', 'tests']),
    include_package_data=True,
    zip_safe=False,
    install_requires=install_requires,
    entry_points={
        # -*- Entry points: -*-
        'console_scripts': [
            'oio_api = oio_rest.app:app.run',
        ],
    },
    tests_require=test_requires,
    extras_require={
        'tests': test_requires,
    }
)
