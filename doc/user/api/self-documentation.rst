.. _Self-documentation:

==================
Self-documentation
==================

The API serves some documentation for the services, objects and fields it
contains. The following urls are available:

.. http:get:: /site-map

   Returns a site map over all valid urls.

   :statuscode 200: No error.

.. http:get:: /(service)/classes

   Returns a JSON representation of the hierarchy's classes and their fields

   :statuscode 200: No error.

.. http:get:: /(service)/(object)/fields

   Returns a list of all fields a given object have.

   :statuscode 200: No error.

.. http:get:: /(service)/(object)/schema

   Returns the JSON schema of an object.

   :statuscode 200: No error.

.. http:get:: /version

   Returns the current version of LoRa

   :statuscode 200: No error.

.. http:get:: /db/truncate

   Requires a configuration setting, in order to be enabled.
   Truncates the database.

   :statuscode 200: No error.

.. caution::

   The structure of each class is not completely analogous to the
   structure of the input JSON as it uses the concept of *"overrides"*.
   This should also be fixed.
