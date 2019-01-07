Sending Messages on the Beskedfordeler
======================================

Using the OIO Mox Library
-------------------------

.. Caution::

   **This section is currently out of date!!! Please refer to the
   examples above for more up to date details.**

This is located in the folder ``agent/`` in the Mox source code
repository.

The library is built with Apache Maven - see pom.xml for Maven dependencies.

To send a command through the message queue, you first need a
``ObjectType`` representing the type of object you want to manipulate.

A collection of these can be defined in a properties file and loaded with ::

    Map<String, ObjectType> objectTypes = ObjectType.load(File propertiesFile)

or ::

    Map<String, ObjectType> objectTypes = ObjectType.load(Properties properties).

The properties must contain a set of keys adhering to the format::

    type.[name].[operation].method = [method]
    type.[name].[operation].path = [path]

For example::

    type.facet.create.method = POST
    type.facet.create.path = /klassifikation/facet

The default agent.properties file defines all of the classes from the
OIOXML hierarchies Klassifikation, Organisation, Sag and Dokument.

You can then get your ObjectType by calling get(String name) on the returned collection.


If you instead want to create your ObjectType yourself, you can create a
new ``ObjectType(String name)`` and add operations to it with ::

    addOperation(String name, ObjectType.Method method, String path)

where

* ``name`` denotes the type of operation (usually "create", "update",
  "passivate" or "delete", but you can specify your own)

* ``method`` denotes the HTTP method to use when connecting to the REST interface.
  Available are: GET, POST, PUT, PATCH, DELETE and HEAD)

* ``path`` denotes the REST path, e.g. "/klassifikation/facet/[uuid]", and ``[uuid]`` will be
  replaced with a uuid you specify when calling the operation



You also need a ``MessageSender``  object, which can be created with::

    new MessageSender(String queueInterface, String queue);

where

* ``queueInterface`` is a hostname/port combination to the RabbitMQ
  instance, e.g. "localhost:5672", and

* ``queue``  is the RabbitMQ queue name, e.g. "incoming".

The queue name and interface port must match what the queue listener is
set up to use; the oio_moxagent listener is currently configured to use
the queue "incoming" for the RabbitMQ service on port 5672.



Now that you have an ObjectType instance and a MessageSender, you can
call any of the following methods:

create
++++++

::

    Future<String> create(MessageSender sender, JSONObject data)
    Future<String> create(MessageSender sender, JSONObject data, String authorization)

Sends a 'create' operation to the message queue, provided that a
'create' operation has been defined in the ObjectType. Put your JSON
document in the ``data`` field, and include an optional authorization
token for the REST interface. The demonstration class already contains
example code on how to obtain such a token (see the
``getSecurityToken()`` method in ``Main.java``) The function immediately
returns a ``Future<String>`` handle, which can be used to obtain the
server response. Calling the ``get()`` method on this handle blocks until a
response is ready, and then returns it in a String.

update
++++++

::

    Future<String> update(MessageSender sender, UUID uuid, JSONObject data)
    Future<String> update(MessageSender sender, UUID uuid, JSONObject data, String authorization)

Sends an 'update' operation to the message queue, provided that an
'update' operation has been defined in the ObjectType. Add the document
UUID to be updated, as well as the JSON document you're updating with.

passivate
+++++++++

::

    Future<String> passivate(MessageSender sender, UUID uuid, String note)
    Future<String> passivate(MessageSender sender, UUID uuid, String note, String authorization)

Sends a 'passivate' operation to the message queue, provided such an
operation has been defined in the ObjectType. Add the document UUID to
be passivated, as well as a note to go with the passivate operation (may
be null).

delete
++++++

::

    Future<String> delete(MessageSender sender, UUID uuid, String note)
    Future<String> delete(MessageSender sender, UUID uuid, String note, String authorization)

Sends a 'delete' operation to the message queue, provided such an
operation has been defined in the ObjectType. Add the document UUID to
be deleted, as well as a note to go with the delete operation (may be
null).

sendCommand
+++++++++++

::

     Future<String> sendCommand(MessageSender sender, String operationName, UUID uuid, JSONObject data)
     Future<String> sendCommand(MessageSender sender, String operationName, UUID uuid, JSONObject data, String authorization)

Sends a custom operationName (useful if you added an operation other
than create, update, passivate or delete). Add a UUID and a JSON Object
as needed by the operation.

This is the more general function, which is used to implement the other
operations.


Using AMQP Messages
-------------------

If you do not wish to use the Java library described above, you can send
messages directly to the AMQP queue where the message handler is
running.

The message handler will recognize four AMQP headers when sending Mox
messages:

* "autorisation" - must contain the SAML token as described above.

* "objektID" - must contain the UUID of the object to manipulate; not
  used with create operations.

* "objekttype" - i.e., OIO class, e.g. "Facet".

* "operation", the action to be performed. Must be one of "create",
  "update", "passivate" or "delete".

Import operations can be performed with the "update" command - but note
that it's also possible to map new commands by editing the
``agent.properties`` file as described above. This could also be used to
specify read operations with GET, if so desired.

The content of the commands, i.e. the actual data, are send as the
payload of the messages. Note that while it is possible to specify a URL
when uploading a document, it is currently *not* possible to upload
the binary contents of a document through the message queue - for this,
the REST interface must be used directly.

For an example of how to create and send Mox messages with Java, please
see the file ObjectType.java in
``agent/src/main/java/dk/magenta/mox/agent``.


Notification Messages
+++++++++++++++++++++

Each time a write operation (create/import/passivate/update/delete) is
performed, an internal notification messages is sent out in the PostgreSQL
database, using the Notify system. These messages can be read from PostgresSQL
and relayed to other services as needed. An example of this is provided in the
form of notify_to_amqp_service.py and the corresponding systemd rules which
allows the program to run as a service. This service will be installed pr default
by the installer. The serivice will create an AMQP message exchange called
"mox.notifications".

To query the status of the service, run the command::
     sudo systemctl status notification

systemctl can also be used to start and stop the service.

The notification message consists of a JSON-string with the following keys:

* "beskedtype" - always contains the value 'Notification'

* "objektID" - contains the UUID of the object.

* "objekttype" - i.e., OIO class, e.g. "Facet".

* "livscykluskode" - i.e. 'Opstaaet', 'Importeret', 'Passiveret', 'Slettet' or
  'Rettet'
