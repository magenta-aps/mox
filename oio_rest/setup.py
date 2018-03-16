#!/usr/bin/env python2.7
# encoding: utf-8

from setuptools import find_packages, setup

version = '0.0.1'
authors = 'C. Agger, Jørgen Ulrik B. Krag, Thomas Kristensen, Seth Yastrov'

test_requires = [
    'pytest',
    'pytest-cov',
    'mock',
    'coverage',
    'freezegun',
    'flake8',
    'flake8-imports',
    'flake8-module-name',
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
    author=authors,
    author_email='info@magenta.dk',
    url='https://github.com/magenta-aps/mox',
    license='Mozilla Public License Version 2.0',
    packages=find_packages(exclude=['ez_setup', 'examples', 'tests']),
    include_package_data=True,
    zip_safe=False,
    setup_requires=[
        'pytest-runner',
        'flake8'
    ],
    install_requires=[
        # -*- Extra requirements: -*-
        'requests==2.12.4',
        'pytz>=2016.10',
        'Flask==0.10.1',
        'Jinja2==2.7.3',
        'MarkupSafe==0.23',
        'Werkzeug==0.10.4',
        'argparse==1.2.1',
        'enum34==1.1.6',
        'itsdangerous==0.24',
        'psycopg2==2.6',
        'wsgiref==0.1.2',
        'python-saml==2.4.0',
        'pexpect==3.3',
        'python-dateutil==2.6.0',
        'egenix-mx-base==3.2.9',
        'pika',
    ],
    entry_points={
        # -*- Entry points: -*-
        'console_scripts': [
            'oio_api = oio_rest.app:main',
        ],
    },
    tests_require=test_requires,
    extras_require={
        'tests': test_requires,
    }
)
