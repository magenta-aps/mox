import argparse
import getpass
import sys

from __init__ import get_token

parser = argparse.ArgumentParser(
    description='request a SAML token'
)

parser.add_argument('user')

parser.add_argument('-v', '--verbose', action='store_true')
parser.add_argument('-f', '--full', action='store_true')
parser.add_argument('-p', '--password')

options = parser.parse_args()

password = options.password or getpass.getpass('Password: ')

token = get_token(options.user, password, options.full, options.verbose)

sys.stdout.write(token)
