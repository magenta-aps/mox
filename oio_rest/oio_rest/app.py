# encoding: utf-8

import os
import traceback

from flask import Flask, jsonify, request, Response
from werkzeug.routing import BaseConverter
from jinja2 import Environment, FileSystemLoader

from custom_exceptions import OIOFlaskException, AuthorizationFailedException
from custom_exceptions import UnauthorizedException, BadRequestException
import auth

app = Flask(__name__)

"""
    Jinja2 Environment
"""

current_directory = os.path.dirname(os.path.realpath(__file__))

jinja_env = Environment(loader=FileSystemLoader(
    os.path.join(current_directory, 'templates', 'html')
))


class RegexConverter(BaseConverter):
    def __init__(self, url_map, *items):
        super(RegexConverter, self).__init__(url_map)
        self.regex = items[0]


app.url_map.converters['regex'] = RegexConverter


@app.route('/get-token', methods=['GET', 'POST'])
def get_token():
    if request.method == 'GET':

        t = jinja_env.get_template('get_token.html')
        html = t.render()
        return html
    elif request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        if username is None or password is None:
            raise BadRequestException("Username and password required")

        try:
            text = auth.get_token(username, password)
        except Exception as e:
            traceback.print_exc()
            raise AuthorizationFailedException(e.message)

        return Response(text, mimetype='text/plain')


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


@app.errorhandler(OIOFlaskException)
def handle_not_allowed(error):
    dct = error.to_dict()
    response = jsonify(dct)
    response.status_code = error.status_code
    return response


def main():
    from settings import BASE_URL
    from klassifikation import KlassifikationsHierarki
    from organisation import OrganisationsHierarki
    from sag import SagsHierarki
    from dokument import DokumentHierarki

    KlassifikationsHierarki.setup_api(base_url=BASE_URL, flask=app)
    SagsHierarki.setup_api(base_url=BASE_URL, flask=app)
    OrganisationsHierarki.setup_api(base_url=BASE_URL, flask=app)
    DokumentHierarki.setup_api(base_url=BASE_URL, flask=app)

    app.run(debug=True)


if __name__ == '__main__':
    main()
