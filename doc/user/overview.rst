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


