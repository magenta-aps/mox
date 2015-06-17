# encoding: utf-8

from flask import Flask, jsonify, request, url_for
from werkzeug.routing import BaseConverter


app = Flask(__name__)


class RegexConverter(BaseConverter):
    def __init__(self, url_map, *items):
        super(RegexConverter, self).__init__(url_map)
        self.regex = items[0]


app.url_map.converters['regex'] = RegexConverter


@app.route('/site-map')
def sitemap():
    links = []
    for rule in app.url_map.iter_rules():
        # Filter out rules we can't navigate to in a browser
        # and rules that require parameters
        if "GET" in rule.methods:
            links.append(str(rule))
            print rule
    return jsonify({"site-map": links})


def main():
    from settings import BASE_URL
    from klassifikation import KlassifikationsHierarki
    from organisation import OrganisationsHierarki

    KlassifikationsHierarki.setup_api(base_url=BASE_URL, flask=app)
    OrganisationsHierarki.setup_api(base_url=BASE_URL, flask=app)
    app.run(debug=True)


if __name__ == '__main__':
    main()
