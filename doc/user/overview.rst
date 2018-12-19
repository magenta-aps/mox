High-level overview
===================

On a high level the MOX actual state database consists of three server
processes and several agents joining them together.

Server processes
----------------

PostgreSQL
    Database server providing the storage of the bi-temporal actual
    state database as well as validation and verification of the basic
    constraints.

Gunicorn
    WSGI server for the oio rest api.
    Ideally used with a frontend HTTP proxy in production.

RabbitMQ
    AMQP message broker providing interprocess communication between
    the various components.


Agents
------

Within the context of the Mox Messaging Service, agents are small
pieces of software which either listen on an AMQP queue and perform
operations on the incoming data, or expose certain operations as a web
service.

The default installation includes the following agents:

MoxDocumentDownload
    Web service for exporting actual state contents as Excel
    spreadsheets.

MoxDocumentUpload
    Web service for importing data from Excel spreadsheets into the
    actual state database.

MoxRestFrontend
    AMQP agent bridging the REST API.

MoxTabel
    AQMP worker agent MoxDocumentDownload & MoxDocumentUpload.
