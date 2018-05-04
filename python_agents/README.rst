MOX python agents
=================

This directory contains the following 2 (legacy) mox agents:

+-------------+----------------+
| MOX Advis   | mox_advis.py   |
+-------------+----------------+
| MOX Elk Log | mox_elk_log.py |
+-------------+ ---------------+

These agents were part of the early iterations of the Lora stack.
However these agents not used in the current release (may be added in the forseeable future).

The two agents are currently unsupported and not part of the default installation procedure.

Update/Dependencies
-------------------

MOX Advis & MOX Elk Log have previouly been coupled with the OIO Rest package.
The agents have now been de-coupled and do not depend on external settings and python dependencies.

However the agents depend on a local OIO Rest module: saml2.py (Saml2_Assertion class).
This dependency is not Python 3 compatible
and will be removed or refactored when the code is moved to Python 3.


Installation
------------
A installation strategy (formula) has been created,
however as previously described the agents have unresolved dependencies.

As such they are not automatically installed as part of the stack.

:NOTE:
    Once the dependencies have been resolve,
    it should be relatively easy to adjust the installation strategy