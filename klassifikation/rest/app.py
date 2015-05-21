# encoding: utf-8

from flask import Flask, jsonify, request, url_for

import settings

from oio_rest import OIOStandardHierarchy, OIORestObject
from klassifikation_objects import Facet, Klasse, Klassifikation
from werkzeug.routing import BaseConverter

app = Flask(__name__)

class RegexConverter(BaseConverter):
    def __init__(self, url_map, *items):
        super(RegexConverter, self).__init__(url_map)
        self.regex = items[0]


app.url_map.converters['regex'] = RegexConverter

# This is basically what comes after '/' after the domain name and port.


class KlassifikationsHierarki(OIOStandardHierarchy):
    """Implement the Klassifikation Standard."""

    _name = "Klassifikation"
    _classes = [Facet, Klasse, Klassifikation]


@app.route('/site-map')
def sitemap():
    links = []
    for rule in app.url_map.iter_rules():
        # Filter out rules we can't navigate to in a browser
        # and rules that require parameters
        if "GET" in rule.methods:
            links.append(str(rule))
            print rule
    return jsonify({ "site-map": links})

if __name__ == '__main__':

    KlassifikationsHierarki.setup_api(base_url=settings.BASE_URL, flask=app)
    
    app.run(debug=True)
