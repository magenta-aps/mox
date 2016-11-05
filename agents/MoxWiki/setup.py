# encoding: utf-8
from setuptools import setup, find_packages

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
        'mwclient==0.8.1',
        'pika==0.10.0',
        'python-dateutil==2.5.3',
        'pytz==2016.7',
        'jinja2',
        'pylru',

        # These are to satisfy the requests module with SSL support
        'pyOpenSSL',
        'ndg-httpsclient',
        'pyasn1'
    ]
)