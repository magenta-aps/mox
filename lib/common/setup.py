#
# Copyright (c) 2017, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

from setuptools import setup

setup(
    name="mox_common_lib",
    version="0.1",
    description="common library for the mox application stack",
    author="Steffen Park",
    author_email="steffen@magenta.dk",
    license="MPL 2.0",
    packages=['oio_rest_lib'],
    zip_safe=False,
    install_requires=[]
)