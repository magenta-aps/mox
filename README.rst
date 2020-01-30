MOX Messaging Service and Actual State Database
===============================================

Introduction
============

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

This is a technical guide. It is split in two:

User documentation
    Contains documentation for the REST API and setup documentation. You are not
    expected to have a profound knowledge of the system as such, but you do have
    to know your way in a Bash prompt — you should be able to change the Apache
    or Nginx configuration and e.g. disable or change the SSL certificate on
    your own.

Developer documentation
    Contains documentation for developers of the mox codebase and building and
    testing instructions.


Licensing
=========

The MOX messaging queue, including the ActualState database, as found
in this project is free software. You are entitled to use, study,
modify and share it under the provisions of `Version 2.0 of the
Mozilla Public License <https://www.mozilla.org/MPL/2.0/>`_ as
specified in the ``LICENSE`` file. The repository is compliant with version 3.0
of the `REUSE Specification <https://reuse.software/>`_.

This software was developed by `Magenta ApS <http://www.magenta.dk>`_. For
feedback, feel  free to open an issue in the `GitHub repository
<https://github.com/magenta-aps/mox>`_.

