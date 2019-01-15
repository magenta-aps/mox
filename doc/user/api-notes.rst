==================
OIO REST API Notes
==================

.. contents:: `Table of contents`
   :depth: 5


Format of JSON body in requests to REST API
-------------------------------------------

Examples of the format of the JSON bodies to supply when invoking the
particular REST operations can be seen in the folder
``interface_test/test_data``.

Please note that the only distinction between an Update and an Import
operation is that in the Import, an object with the corresponding UUID
doesn't exist in the database. If it does, the PUT operation is
interpreted as an Update to replace the entire contents of the object.



Date ranges for Virkning
------------------------

In the XSDs, it's always possible to specify whether the end points are
included or not. In the API, this is presently *not* possible. The
Virkning periods will always default to "lower bound included, upper
bound not included".





