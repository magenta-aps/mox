# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

from enum import Enum

from oio_rest import config


class Operation(Enum):
    CREATE = "Opret"
    READ = "Læs"
    UPDATE = "Ret"
    DELETE = "Slet"
    PASSIVATE = "Passiver"


def get_restrictions(user, object_type, operation):
    """Return restriction scope for this type of object.

    Return the set of restrictions under which <user> may perform <operation>
    on an object of type <object_type>.

    The restrictions are returned as a list of triplets (attributes, states,
    relations) of Python dictionaries specifying the properties which the
    object must satisfy before the user is allowed to manipulate it.

    The object must satisfy all of the conditions within a triplet in
    order to be available for the given operation. That is, the conditions
    within the restriction triplet are combined with the AND operation.

    If the list contains more than one triplet, at least one of them must be
    fulfilled for the object to be available. That is, the triplets in the
    list are combined with the OR operation. This allows the restriction
    module to specify any Boolean expression on the object on a Sum of
    Products normal form.

    A restriction written as

        [({}, {}, {})]

    is trivially true - however, if an operation is always allowed for this
    user, the restrictions module should return None or NULL.

    The trivially false restriction is written as

    []

    - i.e., an empty list.

    Examples:

        * User A in department (OrganisationEnhed) D wants to read a case
          (Sag) which is classified and may only be read by users in that
          department.

          The restrictions module will return [({}, {}, {'Ejer': D.uuid})].

        * User B wishes to change the description of a Klasse used by her own
          department.

          The restrictions module will return [({}, {},
          { 'Redaktører': B.uuid })]. This means that B must be a member of
          the many relation 'Redaktører'.

        * User C wishes to create a new Klassifikation, i.e. an entire new
          classification scheme. If C had been IT staff, this would be allowed
          provided the new Klassifikation was owned by C's Organisation.

          However, C is an ordinary user and is not allowed to create a new
          Klassifikation. The restrictions module will return [], which is
          trivially false.

        * A user wishes to view a document (Dokument) on the municipality's
          intranet. The user is not logged in.

          The restrictions module will return [({},
          { 'FremdriftStatus': 'Publiceret' }, {})]. I.e., a user who is
          not logged in may view only publicly available documents.

        The function which supplies the actual access control restrictionsi
        must have the same signature as this function and must be configured
        with the variables AUTH_RESTRICTION_MODULE and
        AUTH_RESTRICTION_FUNCTION in settings.py. AUTH_RESTRICTION may be any
        module which is accessible on the Python path.

    """
    if not config.get_settings().enable_restrictions:
        return None
    raise NotImplementedError

    # This is the old code. Left for reference, but remove when redesigning.
    # Also see test_restrictions.py.
    # try:
    #     auth_module = import_module(AUTH_RESTRICTION_MODULE)
    #     auth_function = getattr(auth_module, AUTH_RESTRICTION_FUNCTION)
    #     return auth_function(user, object_type, operation)
    # except (AttributeError, ImportError):
    #     print("Config error: Unable to load authorization module!")
    #     raise


def get_auth_restrictions(user, object_type, operation):
    """Sample or dummy implementation - implement and specify in settings."""
    return None  # [
    #    ({'brugervendtnoegle': 'ORGFUNK'}, {'status': 'Publiceret'},  {}),
    #    ({}, {}, {'redaktoerer': 'ddc99abd-c1b0-48c2-aef7-74fea841adae'})
    # ]
