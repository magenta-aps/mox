#!/usr/bin/env python

# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

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


setup(
    name="oio_rest",
    version=version,
    description="Python and PostgreSQL implementation "
    "of the OIO service interfaces.",
    long_description="""\
    Implementation of various object hierarchies from the Danish Government's
    OIOXML standard for the exchange of public administration documents.""",
    classifiers=[],
    keywords="",
    author="Magenta ApS",
    author_email="info@magenta.dk",
    url="https://github.com/magenta-aps/mox",
    license="Mozilla Public License Version 2.0",
    packages=find_packages(exclude=["ez_setup", "examples", "tests"]),
    package_data={
        "oio_rest.db": [
            "sql/*/*/*.sql",
        ],
        "oio_rest": [
            "templates/html/*.html",
            "templates/xml/*.xml",
            "test_auth_data/idp-certificate.pem",
            "default-settings.toml",
        ],
    },
    python_requires=">=3.5",
    include_package_data=True,
    zip_safe=False,
)
