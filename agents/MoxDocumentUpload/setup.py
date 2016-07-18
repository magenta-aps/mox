# encoding: utf-8
from setuptools import setup, find_packages
import sys
import os

version = '0.0.1'
authors = 'C. Agger, Jørgen Ulrik B. Krag, Thomas Kristensen, Seth Yastrov'
setup(
    name='MoxDocumentUpload',
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
        'Flask==0.11.1',
        'requests==2.10.0',
        'requests-toolbelt==0.6.2',
        'werkzeug==0.11.10',
        'amqp==2.0.3',
        'promise==0.4.2'
    ]
)
