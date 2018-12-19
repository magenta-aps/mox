===============================================
MOX Messaging Service and Actual State Database
===============================================

Introduction
============

.. contents::
   :depth: 5

This project contains an implementation of the OIO object model, used
as a standard for data exchange by the Danish government, for use with
a MOX messaging queue.

You can find the current MOX specification here:

http://www.kl.dk/ImageVaultFiles/id_55874/cf_202/MOX_specifikation_version_0.PDF

As an example, you can find the Organisation hierarchy
here:

http://digitaliser.dk/resource/991439

In each installation of MOX, it is possible to only enable
some of the hierarchies, but we provide the following four OIO
hierarchies by default:

* *Klassifikation*
* *Sag*
* *Dokument*
* *Organisation*


Documentation
-------------

The official location for the documentation is:

* http://mox.readthedocs.io/

Please note that as a convention, all shell commands have been
prefixed with a dollar-sign, or ``$``, representing a prompt. You
should exclude this when entering the command in your terminal.

Audience
--------

This is a technical guide. You are not expected to have a profound knowledge of
the system as such, but you do have to know your way in a Bash prompt — you 
should be able to change the Apache configuration and e.g. disable or change
the SSL certificate on your own.


Components
==========

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


Licensing
=========

The MOX messaging queue, including the ActualState database, as found
in this project is free software. You are entitled to use, study,
modify and share it under the provisions of `Version 2.0 of the
Mozilla Public License <https://www.mozilla.org/MPL/2.0/>`_ as
specified in the ``LICENSE`` file.

This software was developed by `Magenta ApS <http://www.magenta.dk>`_. For
feedback, feel  free to open an issue in the `GitHub repository
<https://github.com/magenta-aps/mox>`_.

