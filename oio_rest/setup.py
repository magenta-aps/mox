#!/usr/bin/env python
import io
import os
import pathlib
import re

from setuptools import find_packages, setup


basedir = pathlib.Path(__file__).parent

__init___path = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "oio_rest", "__init__.py"
)
print(__init___path)


# this is the way flask does it
with io.open(__init___path, "rt", encoding="utf8") as f:
    version = re.search(r'__version__ = "(.*?)"', f.read()).group(1)

# extract requirements for pip & setuptools
install_requires = (basedir / 'requirements.txt').read_text().splitlines()
tests_require = (basedir / 'requirements-test.txt').read_text().splitlines()
lint_require = (basedir / 'requirements-lint.txt').read_text().splitlines()

# setuptools doesn't handle external dependencies, yes
dependency_links = [
    l.split('@', 1)[1].strip()
    for l in install_requires + tests_require + lint_require
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
            'sql/*/*/*.sql',
        ],
        'oio_rest': [
            "templates/html/*.html",
            "templates/xml/*.xml",
            "test_auth_data/idp-certificate.pem",
            "default-settings.toml",
        ],
    },
    python_requires='>=3.5',
    install_requires=install_requires,
    extras_require={
        'tests': tests_require,
        'lint': lint_require,
    },
    tests_require=tests_require,
    include_package_data=True,
    zip_safe=False,
    dependency_links=dependency_links,
)
