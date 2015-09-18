# encoding: utf-8

from flask import Flask, jsonify, request
from werkzeug.routing import BaseConverter

from custom_exceptions import OIOFlaskException
from custom_exceptions import UnauthorizedException, BadRequestException
import os
from settings import MOX_BASE_DIR

app = Flask(__name__)


class RegexConverter(BaseConverter):
    def __init__(self, url_map, *items):
        super(RegexConverter, self).__init__(url_map)
        self.regex = items[0]


app.url_map.converters['regex'] = RegexConverter


@app.route('/get-token', methods=['GET', 'POST'])
def get_token():
    if request.method == 'GET':
        return """
        <html>
        <head><title>Get token</title></head>
        <body>
        <form method="POST" action="/get-token">
            <label>
                Username:
                <input name="username" type="text"/>
            </label>
            <br/>
            <label>
                Password:
                <input name="password" type="password"/>
            </label>
            <br/>
            <label>
                STS Address:
                <input name="sts" type="text"
                    value="https://mox.magenta-aps.dk:9443/services/wso2carbon-sts?wsdl" size="80"/>
            </label>
            <br/>
            <input type="submit" value="Request Token"/>
        </form>
        </body>
        </html>
        """
    elif request.method == 'POST':
        import pexpect
        import re
        username = request.form.get('username')
        password = request.form.get('password')
        sts = request.form.get('sts', '')
        if username is None or password is None:
            raise BadRequestException("Parameters username and password are "
                                      "required")

        params = ['gettoken', username]
        if sts != '':
            params.insert(0, "-DstsAddress=" + sts)

        child = pexpect.spawn(os.path.join(MOX_BASE_DIR, '/agent/agent.sh'),
                                           params)
        i = child.expect([pexpect.TIMEOUT, "Password:"])
        if i == 0:
            child.kill(0)
            raise UnauthorizedException("Error requesting token.")
        else:
            child.sendline(password)
        output = child.read()
        print output
        m = re.search("saml-gzipped\s+(.+?)\s", output)
        if m is not None:
            token = m.group(1)
            return jsonify({"saml-gzipped": token})
        else:
            raise UnauthorizedException("Error requesting token: " + output)


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
