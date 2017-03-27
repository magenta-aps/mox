# encoding: utf-8

import os
import datetime
import urlparse
import traceback

from flask import Flask, jsonify, redirect, request, url_for, Response
from werkzeug.routing import BaseConverter
from jinja2 import Environment, FileSystemLoader
from psycopg2 import DataError

from authentication import get_authenticated_user
from log_client import log_service_call

from settings import MOX_BASE_DIR, SAML_IDP_URL
from custom_exceptions import OIOFlaskException, AuthorizationFailedException
from custom_exceptions import BadRequestException
from auth import tokens
import settings

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


@app.route('/')
def root():
    return redirect(url_for('sitemap'), code=308)


@app.route('/get-token', methods=['GET', 'POST'])
def get_token():
    if request.method == 'GET':

        t = jinja_env.get_template('get_token.html')
        html = t.render(settings=settings)
        return html
    elif request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        if username is None or password is None:
            raise BadRequestException("Username and password required")

        try:
            text = tokens.get_token(username, password)
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
    return jsonify({"site-map": sorted(links)})


@app.errorhandler(OIOFlaskException)
def handle_not_allowed(error):
    dct = error.to_dict()
    response = jsonify(dct)
    response.status_code = error.status_code
    return response


@app.errorhandler(404)
def page_not_found(e):
        return jsonify(error=404, text=str(e)), 404


# After request handle for logging.
# Auxiliary functions to get data to be logged.

def get_service_name():
    'Get the hierarchy of the present method call from the request URL'
    u = urlparse.urlparse(request.url)
    urlpath = u.path
    service_name = urlpath.split('/')[1].capitalize()

    return service_name


def get_class_name():
    'Get the hierarchy of the present method call from the request URL'
    url = urlparse.urlparse(request.url)
    class_name = url.path.split('/')[2].capitalize()
    return class_name


@app.after_request
def log_api_call(response):
    if hasattr(request, 'api_operation'):
        service_name = get_service_name()
        class_name = get_class_name()
        time = datetime.datetime.now()
        operation = request.api_operation
        return_code = response.status_code
        msg = response.status
        note = "Is there a note too?"
        user_uuid = get_authenticated_user()
        object_uuid = getattr(request, 'uuid', None)
        log_service_call(service_name, class_name, time, operation,
                         return_code, msg, note, user_uuid, "N/A", object_uuid)
    return response


@app.errorhandler(DataError)
def handle_db_error(error):
    message, context = error.message.split('\n', 1)
    return jsonify(message=message, context=context), 400


def setup_api():

    from settings import BASE_URL
    from klassifikation import KlassifikationsHierarki
    from organisation import OrganisationsHierarki
    from sag import SagsHierarki
    from dokument import DokumentHierarki
    from aktivitet import AktivitetsHierarki
    from indsats import IndsatsHierarki
    from tilstand import TilstandsHierarki
    from log import LogHierarki

    KlassifikationsHierarki.setup_api(base_url=BASE_URL, flask=app)
    LogHierarki.setup_api(base_url=BASE_URL, flask=app)
    SagsHierarki.setup_api(base_url=BASE_URL, flask=app)
    OrganisationsHierarki.setup_api(base_url=BASE_URL, flask=app)
    DokumentHierarki.setup_api(base_url=BASE_URL, flask=app)
    AktivitetsHierarki.setup_api(base_url=BASE_URL, flask=app)
    IndsatsHierarki.setup_api(base_url=BASE_URL, flask=app)
    TilstandsHierarki.setup_api(base_url=BASE_URL, flask=app)


def main():

    setup_api()
    app.run(debug=True)


if __name__ == '__main__':
    main()
