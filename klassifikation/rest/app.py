# encoding: utf-8

from flask import Flask, jsonify, request, url_for

import settings

from oio_rest import OIOStandardHierarchy, OIORestObject
from klassifikation_objects import Facet, Klasse, Klassifikation

app = Flask(__name__)

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
