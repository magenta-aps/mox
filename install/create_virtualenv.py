#!/usr/bin/python

import argparse
import os
from subprocess import call
import shutil
from getch import getch

parser = argparse.ArgumentParser(description='Create a virtual environment')
parser.add_argument('-a', '--always-overwrite', action='store_true')
parser.add_argument('-n', '--never-overwrite', action='store_true')
parser.add_argument('-e', '--environment-name', action='store', default='python-env')
parser.add_argument('basedir')

args = parser.parse_args()

basedir = os.path.abspath(args.basedir)
never_overwrite = args.never_overwrite
always_overwrite = args.always_overwrite and not never_overwrite
environment_name = args.environment_name
environment_dir = os.path.join(basedir, environment_name)

create = False
if os.path.isdir(environment_dir):
    if always_overwrite:
        shutil.rmtree(environment_dir)
        create = True
    elif never_overwrite:
        create = False
    else:
        print "%s already exists" % environment_dir
        # raw_input("Do you want to reinstall it? (y/n)")
        print "Do you want to reinstall it? (y/n)"
        answer = None
        while answer != 'y' and answer != 'n':
            answer = getch()
        create = (answer == 'y')
else:
    create = True

if create:
    print "Creating virtual enviroment '%s'" % environment_dir
    call(['virtualenv', environment_dir])
