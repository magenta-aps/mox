from flask import Flask, render_template, request, redirect, jsonify

import os
import datetime
from werkzeug.utils import secure_filename
import requests
import json
from requests_toolbelt.multipart.encoder import MultipartEncoder

from agent.amqpclient import MessageSender, NoSuchJob
from agent.message import UploadedDocumentMessage
from agent.config import read_properties_files

DIR = os.path.dirname(os.path.realpath(__file__))

config = read_properties_files(DIR + "/moxdocumentupload.conf")

ALLOWED_EXTENSIONS = {'ods', 'xls', 'xlsx'}


def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1] in ALLOWED_EXTENSIONS

templatefile = open("%s/templates/createDocument.json" % DIR, "r")
CREATE_DOCUMENT_JSON = templatefile.read()
templatefile.close()


class MoxFlaskException(Exception):
    status_code = None  # Please supply in subclass!

    def __init__(self, message, payload=None):
        super(MoxFlaskException, self).__init__()
        self.message = message
        self.payload = payload

    def to_dict(self):
        rv = dict(self.payload or ())
        rv['message'] = self.message
        return rv


class NotAllowedException(MoxFlaskException):
    status_code = 403


class NotFoundException(MoxFlaskException):
    status_code = 404


class UnauthorizedException(MoxFlaskException):
    status_code = 401


class BadRequestException(MoxFlaskException):
    status_code = 400


class ServiceException(MoxFlaskException):
    status_code = 500


def getCreateDocumentJson(documentName, mimetype):
    replacements = {
        "titel": documentName,
        "beskrivelse": "MoxDocumentUpload",
        "mimetype": mimetype,
        "brugervendtnoegle": "brugervendtnoegle",
        "virkning.from": datetime.datetime.now().isoformat()
    }
    json = CREATE_DOCUMENT_JSON
    for key, value in replacements.items():
        json = json.replace("${%s}" % key, value)
    return json


app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = '/tmp'

sender = MessageSender(
    config.get("moxdocumentupload.amqp.username"),
    config.get("moxdocumentupload.amqp.password"),
    config.get("moxdocumentupload.amqp.host"),
    config.get("moxdocumentupload.amqp.exchange")
)


@app.route('/', methods=['GET', 'POST'])
def upload():
    if request.method == 'GET':
        return render_template('form.html')
    elif request.method == 'POST':

        # check if the post request has the file part
        if 'file' not in request.files:
            return redirect(request.url)
        file = request.files['file']
        authorization = request.form['token']
        output = request.form.get("output", "html")

        if not file:
            raise BadRequestException("No file submitted")

        # if user does not select file,
        # browser also submits an empty part without filename
        if file.filename == '':
            raise BadRequestException("No file submitted")

        if not allowed_file(file.filename):
            raise BadRequestException("Invalid file extension")

        if not authorization or len(authorization) == 0:
            raise UnauthorizedException("Authtoken missing")

        # Save file to cache
        filename = secure_filename(file.filename)
        destfilepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(destfilepath)

        # Send file to document service
        url = config["moxdocumentupload.rest.host"] + "/dokument/dokument"
        data = MultipartEncoder(
            fields={
                'json': getCreateDocumentJson(filename, file.mimetype),
                'file': (filename, open(destfilepath, 'rb'), file.mimetype)
            }
        )
        headers = {
            "Authorization": authorization,
            "Content-Type": data.content_type
        }
        response = requests.post(url, headers=headers, data=data)
        os.remove(destfilepath)
        if response.status_code != 200 and response.status_code != 201:
            raise ServiceException(
                "Error in document service: %s" % response.text
            )
        try:
            responseJson = json.loads(response.text)
        except ValueError:
            raise ServiceException("Failed to parse document service response")
        if 'uuid' not in responseJson:
            raise ServiceException("Document service didn't return a uuid")
        uuid = responseJson['uuid']

        # Send AMQP message detailing the upload
        amqpMessage = UploadedDocumentMessage(uuid, authorization)
        jobId = sender.send(amqpMessage)

        # Send http response
        jobObject = {'jobId': jobId}
        if output == 'json':
            return jsonify(jobObject)
        elif output == 'html':
            return render_template('waiter.html', **jobObject)


@app.route('/status')
def checkStatus():
    jobId = request.args.get('jobId')
    if jobId is None:
        raise BadRequestException("Missing jobId")
    (properties, body) = sender.getReply(jobId)
    if body is None:
        return jsonify({})
    try:
        data = json.loads(body)
        return jsonify({'response': data})
    except ValueError:
        return jsonify({'response': body})


@app.errorhandler(MoxFlaskException)
def handle_error(error):
    return jsonify(error.to_dict()), error.status_code


if __name__ == '__main__':
    app.run()
