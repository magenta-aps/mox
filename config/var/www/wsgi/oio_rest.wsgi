import sys
import site
import logging
logging.basicConfig(stream=sys.stderr)

activate_this = '/home/mox/mox/oio_rest/python-env/bin/activate_this.py'
execfile(activate_this, dict(__file__=activate_this))


sys.path.append('/home/mox/mox/oio_rest')
# site.addsitedir('/home/mox/mox/oio_rest/python-env/lib/python2.7/site-packages')
from oio_rest.settings import BASE_URL
from oio_rest.klassifikation import KlassifikationsHierarki
from oio_rest.organisation import OrganisationsHierarki
from oio_rest.app import app as application

KlassifikationsHierarki.setup_api(base_url=BASE_URL, flask=application)
OrganisationsHierarki.setup_api(base_url=BASE_URL, flask=application)

