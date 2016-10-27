import sys
import logging
logging.basicConfig(stream=sys.stderr)

activate_this = '/srv/mox/oio_rest/python-env/bin/activate_this.py'
execfile(activate_this, dict(__file__=activate_this))


sys.path.append('/srv/mox/oio_rest')
from oio_rest.settings import BASE_URL
from oio_rest.klassifikation import KlassifikationsHierarki
from oio_rest.organisation import OrganisationsHierarki
from oio_rest.sag import SagsHierarki
from oio_rest.dokument import DokumentHierarki
from oio_rest.log import LogHierarki

from oio_rest.app import app as application

KlassifikationsHierarki.setup_api(base_url=BASE_URL, flask=application)
OrganisationsHierarki.setup_api(base_url=BASE_URL, flask=application)
SagsHierarki.setup_api(base_url=BASE_URL, flask=application)
DokumentHierarki.setup_api(base_url=BASE_URL, flask=application)
LogHierarki.setup_api(base_url=BASE_URL, flask=application)

