.. _ReadOperation:

--------------
Read operation
--------------

To get a single object. Call :http:method:`GET` on the object endpoint with the
UUID of the object appended, e.g.:

.. code-block:: http

    GET /organisation/organisationenhed/1ab754c7-7126-494e-8a4d-9ee3054709fa HTTP/1.1

It will only return information which is currently valid. That is the
information with a :ref:`Valid time` containing the current system time.

To get a information which was valid at another time you can add
``&virkningFra=<datetime>&virkningTil=<datetime>`` Where ``<datetime>`` is a
date/time value. Date and time input is accepted in almost any reasonable
format, including ISO 8601. When reading ``virkning``-periods will always
default to "lower bound included, upper bound not included".

Alternatively ``&virkningstid=<datetime>`` can be used. The results returned
will be those valid at date/time value ``<datetime>,`` giving a 'snapshot' of
the object's state at a given point in time.

To filter on the transaction time,
``&registreretFra=<datetime>&registreretTil=<datetime>`` and
``&registreringstid=<datetime>`` is also available.

See :http:get:`/organisation/organisationenhed/(regex:uuid)` for the complete
reference for read operation on ``organisationenhed``.

Known as a ``Læs`` operation in `the specification <Generelle egenskaber for
services på sags- og dokumentområdet>`_.
