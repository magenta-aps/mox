Testing
=======

.. warning::

    This document is outdated. Note that, among other things, we
    currently don't maintain the MoxRestFrontend agent.

To run the API for testing or development purposes, run::

    $ oio_rest/oio_api.sh

Then, go to ``http://localhost:5000/site-map`` to see a map of all available
URLs, assuming you're running this on your local machine.

The install.sh script creates an Apache VirtualHost for oio rest and
MoxDocumentUpload.

To run the OIO Rest Mox Agent (the one listening for messages and
relaying them onwards to the REST interface), run::

    $ agents/MoxRestFrontend/moxrestfrontend.sh

.. note::
    You can start the agent in the background by running::

        $ sudo service moxrestfrontend start

To test sending messages through the agent, run::

    $ ./test.sh

.. note::
   The install script does not set up an IDP for SAML authentication,
   which is enabled by default. If you need to test without SAML authentication,
   you will need to turn it off as described below.

To request a token for the username from the IdP and output it in
base64-encoded gzipped format, run::

    $ ./auth.sh -u <username> -p

Insert your username in the command argument. You will be prompted to enter
a password.

If SAML authentication is turned on (i.e., if the parameter
``USE_SAML_AUTHENTICATION`` in ``oio_rest/oio_rest/settings.py`` is
`True`), the IDP must be configured correctly — see the corresponding
sections below for instruction on how to do this.

Running the tests
-----------------

OIO Rest has its own unit test suite::

    $ cd oio_rest
    $ python setup.py test

or::

    $ cd oio_rest
    $ ./run_tests.sh

The latter of which will automatically generate a virtual environment, and run the tests
in it.
