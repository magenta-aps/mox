import os

from agent.amqp import MessageListener, NoSuchJob
from agent.config import read_properties_file
from mwclient import Site
from mwclient.errors import LoginError
from requests.exceptions import HTTPError
from pprint import pprint
from inspect import getmembers

DIR = os.path.dirname(os.path.realpath(__file__))

# config = read_properties_file("/srv/mox/mox.conf")

class MoxWiki(MessageListener):

    def __init__(self):

        https = False
        address = 'semawi.magenta.dk'
        api_path = '/'
        agent = 'MoxWiki run by User:Xyz'
        # consumer_token='my_consumer_token',
        # consumer_secret='my_consumer_secret',
        # access_token='my_access_token',
        # access_secret='my_access_secret'
        username='SeMaWi'
        password='SeMaWiSeMaWi'

        try:
            self.site = Site(
                (
                    'https' if https else 'http',
                    address
                ),
                path=api_path,
                clients_useragent=agent,
                max_retries=5,
                # consumer_token=consumer_token,
                # consumer_secret=consumer_secret,
                # access_token=access_token,
                # access_secret=access_secret
            )
        except HTTPError as error:
            status = error.response.status_code
            if status == 404:
                raise Exception("%s. api_path is set to %s. Are you sure this is correct?" % (unicode(error), api_path))
            raise error

        try:
            self.site.login(username, password)
        except LoginError as e:
            raise e

    def wikitest(self):
        pass

    def callback(self, channel, method, properties, body):
        print "got message %s" % unicode(body)

main = MoxWiki()
