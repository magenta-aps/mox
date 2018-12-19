Deployment
==========


System requirements
-------------------

LoRA currently supports Ubuntu 16.04 (Xenial).
We recommend running it on a VM with the following allocation:

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * -
     - CPU
     - Memory
     - Storage
     - Disk type
   * - Minimal
     - 1 core
     - 2 GB
     - 15 GB
     - any *(SSD or HD)*
   * - Test & development
     - 2 cores
     - 4 GB
     - 30 GB
     - SSD *(recommended)*
   * - Production
     - 4 cores
     - 8 GB
     - 60 GB
     - SSD

You should initially provision all the storage space you expect to use,
as adjusting it is somewhat cumbersome. By comparison, increasing or
decreasing CPU and memory is trivial.

Getting started
---------------

To install the OIO REST API, run ``install.sh``::

  $ sudo apt-get install git
  $ git clone https://github.com/magenta-aps/mox
  $ cd mox
  $ ./install.sh

.. note::

   Using the built-in installer should be considered
   a "developer installation". Please note that it *will not* work
   on a machine with less than 1GB of RAM.

   In the current state of the installer,
   we recommend using it only on a newly installed system,
   preferrably in a dedicated container or VM.
   It is our intention to provide more flexible
   installation options in the near future.

The default location of the log directory is::

   /var/log/mox

The following log files are created:

 - Audit log: /var/log/mox/audit.log
 - OIO REST HTTP access log: /var/log/mox/oio_access.log
 - OIO REST HTTP error log: /var/log/mox/oio_error.log

Additionally, a directory for file uploads is created::

   # settings.py
   FILE_UPLOAD_FOLDER = getenv('FILE_UPLOAD_FOLDER', '/var/mox')


The oio rest api is installed as a service,
for more information, see the oio_rest.service.

By default the oio_rest service can be reached as follows::

   http://localhost:8080

Example::

   curl http://localhost:8080/organisation/bruger

.. note::
   In a production environment,
   it is recommended to bind the oio_rest service to a unix socket,
   then expose the socket using a HTTP proxy of your own choosing.

   (Recommended: Nginx or Apache)

   More on how to configure in the advanced configuration document.
   Link: ``Document is currently being written``


Configuration
-------------

Most configurable parameters of oio_rest can be injected with
environment variables, alternatively you may set the parameters
explicitly in the "settings.py" file.

(Please see $ROOT/oio_rest/settings.py)

As mentioned, most parameters are accessible.
If they are NOT set by you, we have provided sensible fallback values.

Example::

   # settings.py

   # DB (Postgres) settings
   DATABASE = getenv('DB_NAME', 'mox')
   DB_USER = getenv('DB_USER', 'mox')
   DB_PASSWORD = getenv('DB_PASS', 'mox')


The oio rest api is served using the wsgi server gunicorn.
The gunicorn server can be configured through the "guniconfig.py" file.

(Please see $ROOT/oio_rest/guniconfig.py)

Similar to the oio rest settings file,
gunicorn can be configured using environment variables: ::

   # guniconfig.py

   # Bind address (Can be either TCP or Unix socket)
   bind = env("GUNICORN_BIND_ADDRESS", '127.0.0.1:8080')
