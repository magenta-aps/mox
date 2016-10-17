import requests
import json

class OIOEntity(object):

    def __init__(self, host, id, token=None):
        self.host = host
        self.id = id
        self.json = {}
        self.load(token)

    def load(self, token=None):
        headers = {}
        if token:
            headers = {'authorization': token}
        response = requests.get(self.host + self.get_path(), headers=headers)
        jsondata = json.loads(response.text)
        self.json = jsondata[self.id][0]

    def get_path(self):
        raise NotImplementedError
