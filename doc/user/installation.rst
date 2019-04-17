============
Installation
============

All the actively developed source code of mox is a Python package located in
:file:`oio_rest`. You can run it in as you see fit. Two methods are described
below. Use the docker image or a Python package in a virtual environment.

.. tip::

   TL;DR: To get a running development environment with postgres, rabbitmq and
   mox, run:

   .. code-block:: bash

      git clone https://github.com/magenta-aps/mox.git
      cd mox
      docker-compose up -d --build

.. todo::

   Document how to install test dependencies when it is formalized in #28498.

Docker
======

The repository contains a :file:`Dockerfile`. This is the recommended way to
install mox both as a developer and in production.

All releases are pushed to Docker Hub at `magentaaps/mox
<https://hub.docker.com/r/magentaaps/mox>`_ under the ``latest`` tag. The
``dev-latest`` tag contains the latest build from the ``development`` branch.

To run mox in docker you need a running docker. To install docker we refer you
to the `official documentation <https://docs.docker.com/install/>`_.

The container requires a connection to a postgres database. It is configured
with the environment variables :py:data:`DB_HOST`, :py:data:`DB_USER` and
:py:data:`DB_PASSWORD`. You can start a the container with:

.. code-block:: bash

    docker run -p 5000:5000 -e DB_HOST=<IP of DB host> -e DB_USER=mox -e DB_PASSWORD=mox magentaaps/mox:latest

This will pull the image from Docker Hub and starts a container in the
foreground. The ``-p 5000:5000`` `binds port
<https://docs.docker.com/engine/reference/commandline/run/#publish-or-expose-port--p---expose>`_
``5000`` of the host machine to port ``5000`` on the container. The ``-e`` `sets
the environment variables
<https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file>`_
in container.

If successful you should see the container initializing database and
finally

.. code-block::

    [2019-04-10 08:22:06 +0000] [1] [INFO] Listening at: http://0.0.0.0:5000 (1)

when the gunicorn server starts up. You should now be able to reach the server
from the host at ``http://localhost:5000``.


If you continue to see ``Postgres is unavailable - sleeping`` your database
configuration most likely wrong. Remember if you set ``DB_HOST=localhost`` the
container will try to connect to a database in the same container, not the host
machine.

For other setting you can set, see :ref:`settings`.

.. todo::
   Document testing dependencies.


Logs
----
The gunicorn access log is output on ``STDOUT`` and error log is output on
``STDERR``. They can be inspected with ``docker logs``.


File upload
-----------
:file:`/var/mox` is the default :py:data:`FILE_UPLOAD_FOLDER`. It can
be mounted as a volume if needed.


Docker-compose
==============

You can use ``docker-compose`` to start up mox and related service such as
postgres and rabbitmq.

A :file:`docker-compose.yml` for development is included. It automatically
starts up `postgres <https://hub.docker.com/_/postgres>`_ and `rabbitmq
<https://hub.docker.com/_/rabbitmq>`_. It sets the environment variabels to
connect them.

It also mounts the current directory in the container and automatically restarts
the server on changes. This enables you to edit the files in :file:`oio_rest`
and the server will be reloaded automatically.

To pull the images and start the three service run:

.. code-block:: bash

    docker-compose up -d --build

The ``-d`` flag move the services to the background. You can inspect the output
of them with ``docker-compose logs <name>`` where ``<name>`` is the name of the
service in :file:`docker-compose.yml`. The ``--build`` flag builds the newest
docker image for ``oio_rest`` from the local :file:`Dockerfile`.

To stop the service again run ``docker-compose stop``. This will stop the
services, but the data will persist. To completely remove the containers and
data run ``docker-compose down``.


From source
===========

All the relevant code is in a Python package located in :file:`oio_rest`.

Prerequisites
-------------

.. ATTENTION DEVELOPER: When you change these prerequisites, make sure to also
   update them in Dockerfile.

The :file:`oio_rest` package requires a few system dependencies. It requires:

* ``python`` >=3.5
* ``pip`` >=10.0.0
* ``setuptools`` >=39.0.1
* ``wheel``
* ``git`` for installing some requirements from :file:`requirements.txt` and
* ``libxmlsec1-dev`` for the Python package ``xmlsec``.

Mox needs to connect to ``postgres9.6``. mox can be configured with
:py:data:`DB_HOST` to connect to any machine. You can install ``postgres9.6`` on
the same machine and leave :py:data:`DB_HOST` as the default value of
``localhost``.

Installation
------------

When the prerequisites are met, you can install mox from a clone of the git
repository.

.. code-block:: bash

   git clone https://github.com/magenta-aps/mox.git
   cd mox/oio_rest
   pip install .

Configuration
-------------

Look through the :ref:`settings` and configure the one you need either as
environment variables or as a config file. The most likely changes are properly
to :py:data:`DB_HOST`, :py:data:`DB_USER` and :py:data:`DB_PASSWORD`.

Database initialization
-----------------------

.. todo::

   Missing. Describe it when #28276 is done.

Run
---

When the database is initialized you can access the `flask cli
<http://flask.pocoo.org/docs/1.0/cli/#cli>`_ with ``python3 -m oio_rest
<command>``. To run the development server run ``python3 -m oio_rest
run``.

Alternative use gunicorn to run a server with ``gunicorn oio_rest.app:app``.
