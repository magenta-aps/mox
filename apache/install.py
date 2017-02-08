#!/usr/bin/python

import argparse
import os

from installutils import DIR, sudo, install_dependencies, expand_template

parser = argparse.ArgumentParser(description='Install Apache configuration')

parser.add_argument('-s', '--skip-system-deps', action='store_true')
parser.add_argument('-d', '--domain', default='localhost', help='server name')

args = parser.parse_args()

# ------------------------------------------------------------------------------

if not args.skip_system_deps:
    print "Installing system dependancies"

    install_dependencies("%s/SYSTEM_DEPENDENCIES" % DIR)

expand_template('mox.conf.in', DOMAIN=args.domain)

sudo('ln', '-svf', os.path.join(DIR, 'mox.conf'),
     '/etc/apache2/sites-available')

sudo('a2ensite', 'mox')
sudo('a2enmod', 'ssl', 'rewrite')

# remove legacy configuration
if os.path.exists('/etc/apache2/sites-available/oio_rest.conf'):
    sudo('a2dissite', 'oio_rest')
    sudo('rm', '-fv', '/etc/apache2/sites-available/oio_rest.conf')

sudo('apachectl', 'graceful')
