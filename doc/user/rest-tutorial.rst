Getting to know LoRa's REST API
===============================

The following small exercises can be used as an inspiration to getting to know
LoRa's REST API. Read :ref:`QueryingData` before moving on. Also, have a look at
the LoRa documentation found in Magenta’s Alfresco system.

.. note::

   The exact end-date for the dateranges are not important, it is however
   important that they are in the future when you do this tutorial.

1. Create an ``organisation`` called e.g. “Magenta” valid from 2017-01-01
   (included) to 2025-12-31 (excluded).
2. Make a query searching for all ``organisation`` in LoRa - confirm that
   Magenta exists in the system.
3. Create an ``organisationenhed`` called “Magenta” (which should be a subunit
   to the ``organisation`` Magenta) active from 2017-01-01 (included) to
   2024-03-14 (excluded). Consider which attributes and relations to set.
4. Create an ``organisationenhed`` called “Copenhagen” (which should be a
   subunit to the ``organisationenhed`` Magenta) active from 2017-01-01
   (included) to 2024-03-14 (excluded). Consider which attributes and relations
   to set.
5. Create an ``organisationenhed`` called “Aarhus” (which should be a subunit of
   the ``organisationenhed`` Magenta) active from 2018-01-01 (included) to
   2025-09-01 (excluded). Consider which attributes and relations to set.
6. Make a query searching for all ``organisationenhed`` in LoRa - confirm that
   Copenhagen and Aarhus exist in the system.
7. Add an ``address`` to the ``organisationenhed`` Aarhus (valid within the
   period where the ``organisationenhed`` is active).
8. Fetch the ``organisationenhed`` Aarhus and verify that the newly added
   ``address`` is present in the response.
9. Add another ``address`` to the ``organisationenhed`` Aarhus (valid in a
   period exceeding the period where the ``organisationenhed`` is active). What
   happens in this case?
10. Remove all ``address`` from the ``organisationenhed`` Aarhus and confirm that
   they are gone afterwards.
11. Make a small script capable of adding ``n`` new ``organisationenhed`` (e.g.
    where 10 < ``n`` < 20) named orgEnhed1, orgEnhed2, orgEnhed3,... These
    ``organisationenhed`` should all be subunits of the ``organisationenhed``
    Copenhagen and they should be active in random intervals ranging from
    2017-01-01 (included) to 2025-12-31 (excluded).
12. Find all active ``organisation`` (if any) in the period from 2017-12-01 to 2025-06-01.
13. What are the names of the ``organisationenhed`` from 11.?
