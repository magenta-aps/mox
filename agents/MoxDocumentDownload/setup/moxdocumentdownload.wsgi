import sys
import logging
logging.basicConfig(stream=sys.stderr)

activate_this = '/srv/mox/agents/MoxDocumentDownload/python-env/bin/activate_this.py'
execfile(activate_this, dict(__file__=activate_this))


sys.path.append('/srv/mox/agents/MoxDocumentDownload')

from moxdocumentdownload.app import app as application

