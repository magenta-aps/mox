Getting to know LoRa's REST API
===============================

The following small exercises can be used as an inspiration to getting to know
LoRa's REST API. Read :ref:`LoRaHOWTO` before moving on. Also, have a look at
the LoRa documentation found in Magenta’s Alfresco system.

1. Create an organisation called e.g. “Magenta” valid from 2017-01-01
   (included) to 2019-12-31 (excluded).
2. Make a query searching for all organisations in LoRa - confirm that Magenta
   exists in the system.
3. Create an organisationenhed called “Copenhagen” (which should be a subunit
   to Magenta) active from 2017-01-01 (included) to 2018-03-14 (excluded).
   Consider which attributes and relations to set.
4. Create an organisationenhed called “Aarhus” (which should be a subunit of
   Magenta) active from 2018-01-01 (included) to 2019-09-01 (excluded).
   Consider which attributes and relations to set.
5. Make a query searching for all organisationenheder in LoRa - confirm that
   Copenhagen and Aarhus exist in the system.
6. Add an address to the org unit in Aarhus (valid within the period where the
   org unit is active).
7. Fetch the org unit Aarhus and verify that the newly added address is
   present in the response.
8. Add another address to the org unit in Aarhus (valid in a period exceeding
   the period where the org unit is active). What happens in this case?
9. Remove all addresses from the Aarhus org unit and confirm that they are
   gone afterwards.
10. Make a small script capable of adding n new org units
    (e.g. where 10 < n < 20) named orgEnhed1, orgEnhed2, orgEnhed3,... These
    org units should all be subunits of the Copenhagen org unit and they
    should be active in random intervals ranging from 2017-01-01 (included) to
    2019-12-31 (excluded).
11. Find all active org (if any) in the period from 2017-12-01 to 2019-06-01.
12. What are the names of the org units from above?
