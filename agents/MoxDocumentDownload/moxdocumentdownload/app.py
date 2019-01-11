# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


#!/usr/bin/python
# -*- coding: utf-8 -*-
import warnings

import requests
import json
import io
import os
import datetime
import threading
from agent.config import read_properties_files, MissingConfigKeyError
from flask import Flask, render_template, request, make_response

DIR = os.path.dirname(os.path.realpath(__file__))

GET_TOKEN = "/get-token"

app = Flask(__name__)

config = read_properties_files(DIR + "/moxdocumentdownload.conf")


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


class ChunkGet(threading.Thread):

    results = []

    def __init__(self, url, token):
        super(ChunkGet, self).__init__()
        self.url = url
        self.token = token

    def get_results(self):
        return self.results

    def run(self):
        item_request = requests.get(
            self.url,
            headers={
                "Authorization": self.token,
                "Content-type": "application/json"
            },
            verify=False
        )
        try:
            response = json.loads(item_request.text)
            if response is not None:
                self.results = response.get("results")
                if self.results is None:
                    raise Exception("Response is None")
            else:
                raise Exception("Response is None")
        except Exception as e:
            msg = e.message
            if 'No JSON object could be decoded' in e.message:
                msg += "\n%s" % item_request.text
            raise Exception(msg)


def extract(host, username, password, objecttypes, load_threaded=10):

    token = get_token(host, username, password)

    register_time = datetime.datetime.today().date() + \
        datetime.timedelta(days=1)

    request_counter = 0
    objects = {}
    for objecttype_name, objecttype_url in objecttypes.iteritems():
        # print "Listing objects of type %s" % objecttype_name
        uuids = []
        for parameterset in [
            "brugervendtnoegle=%", "livscykluskode=Importeret"
        ]:
            list_request = requests.get(
                "%s%s?%s" % (host, objecttype_url, parameterset),
                headers={
                    "Authorization": token,
                    "Content-type": "application/json"
                },
                verify=False
            )
            try:
                response = json.loads(list_request.text)
                uuid_list = response.get("results")[0]
                # print "%d %s items" % (len(uuid_list), objecttype_name)
                uuids.extend(uuid_list)
            except Exception as e:
                msg = e.message
                if 'No JSON object could be decoded' in e.message:
                    msg += "\n%s" % list_request.text
                raise ServiceException(msg)

        objects[objecttype_name] = []
        uuids = list(set(uuids))
        chunksize = 20
        chunks = [
            uuids[i:i+chunksize]
            for i in range(0, len(uuids), chunksize)
        ]

        if load_threaded is not None and load_threaded > 0:
            loaders = []
            for chunk in chunks:
                url = "%s%s?registreretFra=%s&uuid=%s" % (
                    host, objecttype_url, register_time, "&uuid=".join(chunk)
                )
                loader = ChunkGet(url, token)
                loaders.append(loader)

            loader_chunk_size = load_threaded
            loader_chunks = [
                loaders[i:i+loader_chunk_size]
                for i in range(0, len(loaders), loader_chunk_size)
            ]
            chunks_processed = 0
            for loader_chunk in loader_chunks:
                for loader in loader_chunk:
                    loader.start()
                for loader in loader_chunk:
                    loader.join()
                chunks_processed += 1

            for loader in loaders:
                results = loader.get_results()
                for result in results:
                    # print "there are %d results" % len(result)
                    objects[objecttype_name].extend(result)
        else:
            for chunk in chunks:
                url = "%s%s?registreretFra=%s&uuid=%s" % (
                    host, objecttype_url, register_time, "&uuid=".join(chunk)
                )

                item_request = requests.get(
                    url,
                    headers={
                        "Authorization": token,
                        "Content-type": "application/json"
                    },
                    verify=False
                )
                try:
                    response = json.loads(item_request.text)
                    objects[objecttype_name].extend(response.get("results")[0])
                except Exception as e:
                    msg = e.message
                    if 'No JSON object could be decoded' in e.message:
                        msg += "\n%s" % item_request.text
                    raise ServiceException(msg)

                request_counter += 1
                if request_counter % 20 == 0:
                    token = get_token(host, username, password)

    return objects


def get_token(host, username, password):
    """ Get a token from the server"""
    token_url = "%s%s" % (host, GET_TOKEN)
    # print "Obtaining token from %s" % token_url
    token_request = requests.post(
        token_url,
        data={
            'username': username,
            'password': password,
        },
        verify=False
    )
    if not token_request.text.startswith("saml-gzipped"):
        try:
            object = json.loads(token_request.text)
            message = object.get("message")
        except ValueError:
            message = token_request.text
        if "invalid username or password" in message:
            print "wrong pw"
            raise NotAllowedException(message)
        raise ServiceException(message)

    return token_request.text.strip()


def unlist(data, path=[]):
    b = {}
    l = []
    if type(data) == dict:
        for key in data:
            (basedata, listdata) = unlist(data[key], path + [key])
            if basedata is not None:
                b[key] = basedata
            if listdata is not None:
                for item in listdata:
                    l.append({key: item})
        if len(l) == 0:
            l = None
        return (b, l)
    elif type(data) == list:
        for item in data:
            (basedata, listdata) = unlist(item, path)
            if basedata is not None:
                l.append(basedata)
            if listdata is not None:
                for item in listdata:
                    if 'virkning' not in item and 'virkning' in basedata:
                        item['virkning'] = basedata['virkning']
                    l.append(item)
        return (None, l)
    else:
        return (data, None)


def find_child(obj, key):
    if type(obj) == dict:
        for k in obj:
            if k == key:
                return obj[k]
            else:
                retval = find_child(obj[k], key)
                if retval:
                    return retval


def shared_keys(obj1, obj2, exclude=[]):
    shared = []
    for key1 in obj1:
        if key1 in obj2 and key1 not in exclude:
            shared.append(key1)
    return shared


def merge_standard(listdata):
    newlistdata = []
    taken = set()
    for i in range(len(listdata)):
        if True or i not in taken:
            list1 = listdata[i]
            merged = {}
            merged.update(list1)
            flaf = set()
            merge = False
            for j in range(i+1, len(listdata)):
                if j not in taken:
                    list2 = listdata[j]
                    if list1.get('Fra') == list2.get('Fra') and \
                            list1.get('Til') == list2.get('Til'):
                        shared = shared_keys(merged, list2, ['Til', 'Fra'])
                        same = True
                        for s in shared:
                            if merged[s] != list2[s]:
                                same = False
                        if same:
                            merged.update(list2)
                            taken.add(i)
                            taken.add(j)
                            flaf.add(i)
                            flaf.add(j)
                            merge = True
            if merge:
                newlistdata.append(merged)
    for i in range(len(listdata)):
        if i not in taken:
            newlistdata.append(listdata[i])
    return newlistdata


def merge_aggressive(listdata):
    newlistdata = {}
    separator = "|"
    for item in listdata:
        for key, value in item.iteritems():
            if key != "Til" and key != "Fra":
                if key in newlistdata:
                    newlistdata[key] += separator + value
                else:
                    newlistdata[key] = value
    return [newlistdata]


def fmt_date(date):
    if date and date != 'infinity':
        return date
    else:
        return ''


def convert_virkning(virkning):
    obj = {
        'Til': fmt_date(virkning['to']),
        'Fra': fmt_date(virkning['from'])
    }
    if 'notetekst' in virkning:
        obj['Virkning_note'] = virkning['notetekst']
    return obj


def compare_virkning(virkning1, virkning2):
    return \
        virkning1['to'] == virkning2['to'] and \
        virkning1['from'] == virkning2['from']


def convert(row, structure, include_virkning=True):
    converted = {}
    # print row
    for key in structure:
        path = structure[key]
        ptr = row

        try:
            p = None
            for p in path:
                if p == 'registrering':
                    continue
                if '|' in p:
                    options = p.split('|')
                    for option in options:
                        if option in ptr:
                            p = option
                            break
                ptr = ptr[p]
                if include_virkning and 'virkning' in ptr:
                    converted.update(convert_virkning(ptr['virkning']))
            if p == 'urn' and ptr.startswith('urn:'):
                ptr = ptr[len('urn:'):]
            converted[key] = ptr
        except:
            pass
    return converted


def fix_rowset(rows):
    STATUS_CODE = 'Livscykluskode'
    STATUS_CREATED = 'Opstaaet'
    STATUS_UPDATED = 'Rettet'
    STATUS_DELETED = 'Slettet'
    STATUS_IMPORTED = 'Importeret'

    ACTION_CODE = 'Operation'
    ACTION_CREATE = 'opret'
    ACTION_UPDATE = 'ret'
    ACTION_DELETE = 'slet'

    lifecycles_detected = set()
    if len(rows) > 1:
        rows.sort(lambda a, b: a['Tidsstempel'] > b['Tidsstempel'])
    for row in rows:
        lifecycles_detected.add(row[STATUS_CODE])
    for row in rows:
        row[ACTION_CODE] = ACTION_UPDATE
    if len(rows) > 1:
        persistent_attributes = ['BrugervendtNoegle', 'Publiceret']
        attribute_storage = {}
        for attribute in persistent_attributes:
            for row in rows:
                if attribute in row:
                    attribute_storage[row['Tidsstempel']] = {
                        attribute: row[attribute]
                    }
            for row in rows:
                if attribute not in row:
                    timestamp = row['Tidsstempel']
                    if timestamp in attribute_storage and \
                            attribute in attribute_storage[timestamp]:
                        row[attribute] = \
                            attribute_storage[timestamp][attribute]

    """
    if STATUS_DELETED in lifecycles_detected:
        deletion_note = ''
        for row in rows:
            if 'Note' in row:
                deletion_note = row['Note']
                del row['Note']
        rows.append({
            ACTION_CODE: ACTION_DELETE,
            STATUS_CODE: STATUS_DELETED,
            'Note': deletion_note,
            'objektID': rows[0]['objektID'],
            'Fra': rows[-1]['Fra'],
            'Til': rows[-1]['Til']
        })
    """
    return rows


def csvrow(row, headers):
    line = []
    for header in headers:
        line.append(row.get(header, ''))
    return ','.join(["\"%s\"" % x.replace('"', '""') for x in line])


def format(data, mergelevel=1):
    output = {}
    structure_collection = json.load(
        app.open_instance_resource("structure.json")
    )
    for objecttype_name, items in data.iteritems():
        # print "Type %s has %d objects" % (objecttype_name, len(items))
        rows = []
        structure = structure_collection[objecttype_name]
        baseheaders = [
            'Operation', 'objektID', 'Fra', 'Til', 'BrugervendtNoegle'
        ]
        otherheaders = []
        for item in items:
            id = item['id']
            itemrows = []
            for registrering in item['registreringer']:
                registreringrows = []

                (basedata, listdata) = unlist(registrering)

                if listdata is None:
                    listdata = []
                if basedata is None:
                    basedata = {}
                converted_listdata = [
                    convert(item, structure)
                    for item in listdata
                ]
                converted_basedata = convert(basedata, structure)

                if mergelevel == 0:
                    merged = converted_listdata
                elif mergelevel == 2:
                    merged = merge_aggressive(converted_listdata)
                else:
                    merged = merge_standard(converted_listdata)

                for rowpart in merged:
                    row = {}
                    row.update(converted_basedata)
                    row.update(rowpart)
                    row['objektID'] = id
                    registreringrows.append(row)
                itemrows.extend(fix_rowset(registreringrows))
            rows.extend(itemrows)

        for row in rows:
            for key in row:
                if key not in otherheaders:
                    otherheaders.append(key)
            # Kill the operation cell
            row['Operation'] = ''

        baseheaders = [x for x in baseheaders if x in otherheaders]
        otherheaders = [x for x in otherheaders if x not in baseheaders]
        otherheaders.sort()
        headers = baseheaders + otherheaders
        output[objecttype_name] = {'headers': headers, 'rows': rows}
    return output


def writefile(filename, data):
    outfile = io.open(filename, 'w')
    outfile.write(data)
    outfile.close()


OBJECTTYPE_MAP = {
    "klassifikation": "/klassifikation/klassifikation",
    "klasse": "/klassifikation/klasse",
    "facet": "/klassifikation/facet",
    "organisation": "/organisation/organisation",
    "organisationenhed": "/organisation/organisationenhed",
    "organisationfunktion": "/organisation/organisationfunktion",
    "bruger": "/organisation/bruger"
}


def print_error(message):
    print "Content-Type: text/plain\n\n"
    print message


def require_parameter(parametername):
    if parametername not in request.form:
        raise BadRequestException(
            "Please specify the '%s' parameter" % parametername
        )


@app.route('/', methods=['GET', 'POST'])
def main():
    if request.method == 'GET':
        return render_template('form.html')
    elif request.method == 'POST':
        require_parameter('type')
        objecttype = request.form['type']
        print objecttype
        if objecttype not in OBJECTTYPE_MAP:
            raise BadRequestException(
                "The type parameter must be one of the following: %s" %
                ", ".join(OBJECTTYPE_MAP.keys())
            )

        require_parameter('username')
        username = request.form['username']

        require_parameter('password')
        password = request.form['password']

        mergelevel = request.form.get('merge', 1)
        try:
            mergelevel = int(mergelevel)
            if mergelevel not in [0, 1, 2]:
                raise BadRequestException(
                    "'merge' parameter must be 0, 1 or 2. Default is 1"
                )
        except ValueError:
            raise BadRequestException(
                "'merge' parameter must be 0, 1 or 2. Default is 1"
            )

        try:
            server = config['moxdocumentdownload.rest.host']
        except KeyError as e:
            raise MissingConfigKeyError(str(e))
        objects = extract(
            server,
            username, password,
            {objecttype: OBJECTTYPE_MAP[objecttype]}
        )
        data = format(objects, mergelevel)
        objectdata = data[objecttype]
        filedata = u'\n'.join(
            [u','.join(objectdata['headers'])] +
            [
                csvrow(row, objectdata['headers'])
                for row in objectdata['rows']
            ]
        )

        response = make_response(filedata)
        response.headers['Content-Type'] = 'text/csv; charset=utf-8'
        response.headers['Content-Disposition'] = \
            "attachment; filename=\"%s.csv\"" % objecttype
        return response


@app.errorhandler(MoxFlaskException)
def handle_error(error):
    return error.message, error.status_code
