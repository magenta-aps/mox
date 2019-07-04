.. _Settings:

========
Settings
========


``oio_rest`` has various configurable parameters. This file describes how to
configure the program. There are default settings, as shown in
``oio_rest/oio_rest/default-settings.toml``. These can be overwritten by two
files that you can point to with environment variables:


.. py:data:: MOX_ENV_CONFIG_PATH

    Path to a toml settings file. This overwrites the default settings, but has
    lower precedens than user settings. The purpose of this file is to
    configure environments. We use it for docker.


.. py:data:: MOX_USER_CONFIG_PATH

    Point this to a toml file with your desired settings. The settings in this
    file has the highest precedens.


This is the content of ``oio_rest/oio_rest/default-settings.toml``:

.. literalinclude:: ../../oio_rest/oio_rest/default-settings.toml
    :language: toml
    :lines: 9-
