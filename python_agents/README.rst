MOX python agents
=================

This directory contains the following 2 (legacy) mox agents:
    * MOX Advis (mox_advis.py)
    * MOX Elk Log (mox_elk_log.py)

These agents were part of the early iterations of the Lora stack.
However these agents not used in the upcoming releases (for the forseeable future).

As such the agents have been excluded from the default installation procedure,
until the code base is evalutated and updated.

Update/Dependencies
-------------------

MOX Advis & MOX Elk Log have previouly been coupled with the OIO Rest package.
The agents have now been de-coupled and do not depend on external settings and python dependencies.

However the agents depend on a local OIO Rest module: saml2.py (Saml2_Assertion class).
This dependecy is not currently up-to-date and will be either removed or refactored.
