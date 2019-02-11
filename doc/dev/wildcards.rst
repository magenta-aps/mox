.. _dev-wildcards:

Wildcards
=========

When making a :ref:`SearchOperation` with wildcards, a lot happens. Going from
the *bottom* of the stack the following happens:

In SQL the match between two strings is made with `ILIKE from PostgresSQL
<https://www.postgresql.org/docs/9.5/functions-matching.html#FUNCTIONS-LIKE>`_.
It is a case-insensitive string match that supports the wildcard operators ``_``
(underscore) to match a single character and ``%`` (percent sign) to match zero
or more characters. To match a litteral underscore or percentage sign you must
escape it with a single backslash as ``\_`` or ``\%``


In :file:`/oio_rest/oio_rest/utils/build_registration.py` all incomming
underscores ``_`` are replaced by an escaped undercore ``\_``. This means it is
not possible for the REST API user to send an underscore wildcard operator to
SQL. This may change in the future.


Flask et. al. take care of decoding :rfc:`RFC 3986 <3986#section-2>`
percentage-encoded URIs. This means a percentage sign followed by two case
insensitive hexidecimal signs (``0-F``) is decoded into the corresponding ASCII
symbol. E.g. a ``%45`` in an URI is decoded to ``E`` in SQL and ``%25`` is
decoded to ``%``. However a percentage sign followed by something where the
first character is anything other than a hexidecimal sign is ignored. E.g.
``%g4`` in an URI also remains ``%g4`` in SQL and ``%magenta`` remains
``%magenta``.

These three mechanisms combined results in some very novel behavior. See the
table below:

=================== ============ ============== =====================================================
URI Query           PGSQL        RegEx          Matches
=================== ============ ============== =====================================================
``jkl``             ``jkl``      ``^jkl$``      the string ``jkl``
``_jkl``            ``\_jkl``    ``^_jkl$``     a litteral underscore followed by ``jkl``
``%jkl``/``%25jkl`` ``%jkl``     ``^.*jkl$``    zero or more of any characters followed by ``jkl``
``%abc``            ``�c``       ``^�c$``       the character 0xAB followed by ``c``
``%afdeling``       ``�deling``  ``^�deling$``  the character 0xAF followed by ``deling``
``E6``/``%456``     ``E6``       ``^E6$``       the string ``E6``
``%25456``          ``%456``     ``^.*456$``    zero or more of any characters followed by ``456``
``\_jkl``           ``\\_jkl``   ``^\\_jkl$``   a ``\`` followed by any character followed by ``jkl``
=================== ============ ============== =====================================================

The best way to avoid most of the confusion is to always percentage-encode your
URI and never write ``\_`` in your query.


.. attention::

   **Always** use :rfc:`RFC 3986 <3986#section-2>` percentage-encoding for your
   search URI!
