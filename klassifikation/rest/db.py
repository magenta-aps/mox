import psycopg2


def create_facet(note, attributes, states, relations): 
    """Create a new facet by calling the stored procedure.

    Create a new facet by calling actual_state_create_or_import_facet. It is
    necessary to map the parameters to our custom PostgreSQL data types.
    """
    pass

