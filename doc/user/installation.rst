============
Installation
============

All the active developed source code of mox is a python package located in
:file:`oio_rest`. You can run it in as you see fit. Two methods are describe
below. Use the docker image or a python package in a virtual environment.

.. tip::

   TL;DR: To get a running development environment with postgres, rabbitmq and
   mox, run:

   .. code-block:: bash

      git clone https://github.com/magenta-aps/mox.git
      cd mox
      docker-compose up -d --build

Docker
======

The repository contains a :file:`Dockerfile`. This is the recommended way to
install mox both as a developer and in production.

All releases are pushed to Docker Hub at `magentaaps/mox
<https://hub.docker.com/r/magentaaps/mox>`_ under the ``latest`` tag. The
``dev-latest`` tag containes the latest build from the ``development`` branch.

To run mox in docker you need a running docker. To install docker we refer you
to the `official documentation <https://docs.docker.com/install/>`_.

The container requires a connection to a postgres database. It is configured
with the envionment variables :py:data:`DB_HOST`, :py:data:`DB_USER` and
:py:data:`DB_PASSWORD`. You can start a the container with:

.. code-block:: bash

    docker run -p 5000:5000 -e DB_HOST=<IP of DB host> -e DB_USER=mox -e DB_PASSWORD=mox magentaaps/mox:latest

This will pull the image from Docker Hub and starts a container in the
foreground. The ``-p 5000:5000`` `binds port
<https://docs.docker.com/engine/reference/commandline/run/#publish-or-expose-port--p---expose>`_
``5000`` of the host machine to port ``5000`` on the container. The ``-e`` `sets
the envionment variables
<https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file>`_
in container.

If sucessfull you should see the container initializing database and
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

In addition the audit log is written to :file:`/var/log/mox/audit.log`. It can
be mounted as a volume if needed. The location is determined by
:py:data:`AUDIT_LOG_FILE`.


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
<https://hub.docker.com/_/rabbitmq>`_. It sets the envionment variabels to
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

.. todo::

   Write this section. Only focus on the python package, its dependencies and
   settings.
