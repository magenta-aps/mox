.. _DeleteOperation:

----------------
Delete operation
----------------

.. note::

   This describes deletion of whole objects. To delete part of an object see
   :ref:`DeleteAttr`.

An object is deleted by sending a :http:method:`DELETE`-request. This might e.g.
look like this:

.. code-block:: http

   DELETE /organisation/organisationenhed/862bb783-696d-4345-9f63-cb72ad1736a3 HTTP/1.1


After an object is deleted, it cannot be retrieved by a :ref:`ReadOperation`,
:ref:`ListOperation` and :ref:`SearchOperation` unless the ``registreretTil``
and/or ``registreretFra`` indicate a period where it did exist.

Known as a ``Slet`` operation in `the specification <Generelle egenskaber for
services på sags- og dokumentområdet>`_.
