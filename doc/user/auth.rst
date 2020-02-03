.. _auth:

SAML based single sign-on (SSO)
===============================

Authentication in LoRa is based on SAML 2.0 single sign-on.
Support for this is implemented through the module
`Flask SAML SSO <https://github.com/magenta-aps/flask_saml_sso>`_.

Once a user has been authenticated, a session is created containing the
attributes given to us from the IdP, e.g. the Active Directory groups the
user belongs to

The module implements a shared session store which provides a shared session
between applications implementing the auth module. This makes it possible to
authenticate users through a user-facing application, while keeping LoRa and
its REST interface hidden externally, while still retaining authentication.

Instructions on using and configuring auth in Flask SAML SSO is
detailed in the documentation for
`OS2mo <https://os2mo.readthedocs.io/en/latest/dev/auth.html>`_
which depends on LoRa and uses the same auth module.
