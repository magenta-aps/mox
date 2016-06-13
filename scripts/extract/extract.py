#!/usr/bin/python

import requests
import json
import io

GET_TOKEN = "/get-token"

def extract(server, username, password, objecttypes, https=True):

    schema = "https://" if https else "http://"

    """ Get a token from the server"""
    token_url = "%s%s%s" % (schema, server, GET_TOKEN)
    print "Obtaining token from %s" % token_url
    token_request = requests.post(
        token_url,
        data={
            'username': username,
            'password': password,
            'sts': "https://%s:9443/services/wso2carbon-sts?wsdl" % server
        }
    )
    if not token_request.text.startswith("saml-gzipped"):
        try:
            object = json.loads(token_request.text)
            message = object.get("message")
        except ValueError:
            message = token_request.text
        raise Exception(message)
    token = token_request.text.strip()
    print "Token obtained"

    """List objects"""
    objects = {}
    for objecttype_name, objecttype_url in objecttypes.iteritems():
        print "Listing objects of type %s" % objecttype_name
        uuids = []
        for parameterset in ["brugervendtnoegle=%", "livscykluskode=Slettet"]:
            list_request = requests.get(
                "%s%s%s?%s" % (schema, server, objecttype_url, parameterset),
                headers={
                    "Authorization": token,
                    "Content-type": "application/json"
                }
            )
            try:
                response = json.loads(list_request.text)
                uuid_list = response.get("results")[0]
                print "%d %s items" % (len(uuid_list), objecttype_name)
                uuids.extend(uuid_list)
            except Exception as e:
                print e

        objects[objecttype_name] = []
        for uuid in uuids:
            item_request = requests.get(
                "%s%s%s/%s" % (schema, server, objecttype_url, uuid),
                headers={
                    "Authorization": token,
                    "Content-type": "application/json"
                }
            )
            try:
                response = json.loads(item_request.text)
                objects[objecttype_name].append(response.get(uuid)[0])
            except Exception as e:
                print e
    return objects




def _unlist(data, path=[]):
    b = {}
    l = []
    if type(data) == dict:
        for key in data:
            (basedata, listdata) = _unlist(data[key], path + [key])
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
            (basedata, listdata) = _unlist(item, path)
            if basedata is not None:
                l.append(basedata)
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

def merge(listdata):
    newlistdata = []
    taken = set()
    for i in range(len(listdata)):
        if True or not i in taken:
            list1 = listdata[i]
            merged = {}
            merged.update(list1)
            flaf = set()
            merge = False
            for j in range(i+1, len(listdata)):
                if not j in taken:
                    list2 = listdata[j]
                    if list1.get('Fra') == list2.get('Fra') and list1.get('Til') == list2.get('Til'):
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
    for key in structure:
        path = structure[key]
        ptr = row

        try:
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
            #print "SUCCESS: %s => %s" % (path, key)
        except:
            #print "FAILURE: %s => %s" % (path, key)
            pass
    return converted

def csvrow(row, headers):
    line = []
    for header in headers:
        line.append(row.get(header,''))
    return ','.join(["\"%s\"" % x for x in line])

def format(data):
    structure_collection = json.load(open("structure.json"))
    for objecttype_name, items in data.iteritems():
        rows = []
        structure = structure_collection[objecttype_name]
        baseheaders = ['objektID', 'Fra', 'Til', 'BrugervendtNoegle']
        otherheaders = []
        for item in items:
            id = item['id']
            print "%d registreringer" % len(item['registreringer'])
            for registrering in item['registreringer']:
                print registrering

                print "------------------"
                print "UNLIST"
                (basedata, listdata) = _unlist(registrering)
                print "%d listdata items" % len(listdata)

                print "------------------"
                print "CONVERT"
                converted_listdata = [convert(item, structure) for item in listdata]
                converted_basedata = convert(basedata, structure)
                print "Base %s" % (converted_basedata)
                for i in range(len(converted_listdata)):
                    print "List %d %s" % (i, converted_listdata[i])

                print "------------------"
                print "MERGE"
                merged = merge(converted_listdata)
                print "%d merged listdata items" % len(merged)

                print "------------------"
                print "APPLY BASEDATA AND ID"
                for rowpart in merged:
                    row = {}
                    row.update(converted_basedata)
                    row.update(rowpart)
                    row['objektID'] = id
                    rows.append(row)
                    for key in row:
                        if key not in otherheaders and key not in baseheaders:
                            otherheaders.append(key)
        otherheaders.sort()
        headers = baseheaders + otherheaders

        print "------------------"
        print "WRITE TO OUTPUT FILE %s.csv" % objecttype_name
        outfile = io.open("%s.csv" % objecttype_name, 'w')
        outfile.write(u','.join(headers))

        lines = list(set([csvrow(row, headers) for row in rows]))
        lines.sort()

        for line in lines:
            outfile.write(u"\n" + line)
        outfile.close()

objects = extract(
    "moxtest.magenta-aps.dk",
    "admin", "admin",
    {
        "klassifikation": "/klassifikation/klassifikation",
        "klasse": "/klassifikation/klasse",
        "facet": "/klassifikation/facet",
        "organisation": "/organisation/organisation",
        "organisationenhed": "/organisation/organisationenhed",
        "organisationfunktion": "/organisation/organisationfunktion",
        "bruger": "/organisation/bruger"
    }
)
#objects = json.load(open("data.json", 'r'))
format(objects)
