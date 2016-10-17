# encoding: utf-8
from setuptools import setup, find_packages
import sys
import os

version = '0.0.1'
authors = 'Lars Peter Thomsen'
setup(
    name='MoxWiki',
    version=version,
    description="",
    long_description="",
    classifiers=[],
    keywords='',
    author=authors,
    author_email='info@magenta.dk',
    url='https://github.com/magenta-aps/mox',
    license='Mozilla Public License Version 2.0',
    packages=find_packages(exclude=['ez_setup', 'examples', 'tests']),
    include_package_data=True,
    zip_safe=False,
    install_requires=[
        # -*- Extra requirements: -*-
        'promise==0.4.2',
        'mwclient==0.8.1'
    ]
)