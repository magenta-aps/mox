.. _SearchOperation:

----------------
Search operation
----------------

You can also *search* for an object by specifying values of attributes or
relations as search parameters. You can, e.g., find all ``organisation`` by
searching for any value of ``brugervendtnoegle``:

.. code-block:: http

    GET /organisation/organisation?brugervendtnoegle=% HTTP/1.1

All search parameters which search on an attribute value of type TEXT use
case-insensitive matching, with the possibility to use wildcards. Other
value types use a simple equality operator.

The wildcard character ``%`` (percent sign) may be used in these search
parameter values. This character matches zero or more of any characters.

If it is desired to search for attribute values of type TEXT which contain ``%``
themselves, then the character must be escaped in the search parameters with a
backslash, like, for example: ``abc\\%def`` would match the value ``abc%def``.
Contrary, to typical SQL LIKE syntax, the character ``_`` (underscore) matches
only the underscore character (and not "any character").

``bvn`` can be used as shorthand for ``brugervendtnoegle``, which is an
attribute field that all objects have, but apart from that, the attribute names
should be spelled out. Search parameter names are case-insensitive.


Search parameters may be combined and may include the time restrictions as for
:ref:`ListOperation`, so it is possible to search for a value which must exist
at a given time or interval.

Note that while the result of a :ref:`ListOperation` or :ref:`ReadOperation`
operation is given as the JSON representation of the object(s) returned, the
result of a :ref:`SearchOperation` operation is always given as a list of UUIDs
which may later be retrieved with a list or read operation - e.g:

.. code-block:: http

    GET /organisation/organisationenhed?brugervendtnoegle=Direktion&tilhoerer=urn:KL&enhedstype=urn:Direktion HTTP/1.1

    {
    "results": [[
        "7c6e38f8-e5b5-4b87-af52-9693e074f5ee",
        "9765cdbf-9f42-4e9d-897b-909af549aba8",
        "3ca64809-acdb-443f-9316-aabb2ee6aff7",
        "3eaa730c-7800-495a-9c6b-4688cdf7a61f",
        "7d305acc-2a85-420b-9557-feead3dae339"
        ]]
    }

Known as a ``Søg`` operation in `the specification <Generelle egenskaber for
services på sags- og dokumentområdet>`_.

.. _PagedSearchOperation:

Paged search
------------

The search function supports paged searches by adding the parameters
``maximalantalresultater`` (max number of results) and ``foersteresultat``
(first result).

Since pagination only makes sense if the order of the results are predictable
the search will be sorted by ``brugervendtnoegle`` if pagination is used.


Advanced search
---------------

It is possible to search for relations (links) as well by specifying
the value, which may be either an UUID or a URN. E.g., for finding all
instances of ``organisationenhed`` which belongs to ``Direktion``:

.. code-block:: http

    GET /organisation/organisationenhed?tilknyttedeenheder=urn:Direktion HTTP/1.1


When searching on relations, one can limit the relation to a specific object
type by specifying a search parameter of the format::

    &<relation>:<objecttype>=<uuid|urn>

Note that the objecttype parameter is case-sensitive.

It is only possible to search on one ``DokumentVariant`` and ``DokumentDel`` at
a time. For example, if ::

    &deltekst=a&underredigeringaf=<UUID>

is specified, then the search will return documents which have a ``DokumentDel``
with ``deltekst="a"`` and which has the relation ``underredigeringaf=<UUID>``.
However, if the deltekst parameter is omitted, e.g. ::

    &underredigeringaf=<UUID>

Then, all documents which have at least one ``DokumentDel`` which has the given
UUID will be returned.

The same logic applies to the ``varianttekst`` parameter. If it is not
specified, then all variants are searched across. Note that when
``varianttekst`` is specified, then any ``DokumentDel`` parameters apply only to
that specific variant. If the ``DokumentDel`` parameters are matched under a
different variant, then they are not included in the results.


Searching on ``Sag``-``JournalPost``-relations
----------------------------------------------

.. warning::

   This section should be moved to a API reference in the future.

To search on the sub-fields of the ``JournalPost`` relation in ``Sag``, requires
a special dot-notation syntax, due to possible ambiguity with other search
parameters (for example, the ``titel`` parameter).

The following are some examples::

  &journalpostkode=vedlagtdokument
  &journalnotat.titel=Kommentarer
  &journalnotat.notat=Læg+mærke+til
  &journalnotat.format=internt
  &journaldokument.dokumenttitel=Rapport+XYZ
  &journaldokument.offentlighedundtaget.alternativtitel=Fortroligt
  &journaldokument.offentlighedundtaget.hjemmel=nej

All of these parameters support wildcards (``%``) and use case-insensitive
matching, except ``journalpostkode``, which is treated as-is.

Note that when these parameters are combined, it is not required that the
matches occur on the *same* ``JournalPost`` relation.

For example, the following query would match any ``Sag`` which has one or more
``JournalPost`` relations which has a ``journalpostkode = "vedlagtdokument"``
AND which has one or more ``JournalPost`` relations which has a
``journaldokument.dokumenttitel = "Rapport XYZ"`` ::

  &journalpostkode=vedlagtdokument&journaldokument.dokumenttitel=Rapport+XYZ
