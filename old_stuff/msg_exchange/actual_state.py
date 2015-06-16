#!/usr/bin/env python


import psycopg2

from datetime import datetime


class DBConnection:
    """Create a DB connection and return cursor for access.
    
    Utility class for accessing database. Will create a connection and provide
    access through a single cursor."""

    _connection = None
    _cursor = None

    def __init__(self, database='mox', username='mox', password=None):
        # Will raise exception if connection fails.
        try:
            self._connection = psycopg2.connect(
                database=database, user=username, password=password
            )
        except psycopg2.DatabaseError as e:
            # TODO: Do proper logging
            print str(e)
            raise

    def __call__(self):
        if not self._cursor:
            self._cursor = self._connection.cursor()
        return self._cursor

    def __del__(self):
        self._connection.close()


registration_fields = ['id', 'timeperiod', 'livscykluskode', 'brugerref',
                       'note']
attributter_fields = ['name', 'id', 'virkning']


def read_object(uuid, system_time=datetime.now(),
                application_time=datetime.now()): 
    """Retrieve an object from the actual state DB with a given UUID."""

    to_dict = lambda l1, l2: { f : v for f, v in zip(l1, l2) }
    sqfields = lambda fields: ', '.join(fields)
    # First, get registration
    conn = DBConnection()
    sql = """SELECT {0} FROM REGISTRERING WHERE 
                     ObjektID = '{1}' AND 
                     TIMESTAMPTZ '{2}' <@ timeperiod
           """.format(sqfields(registration_fields), uuid, system_time)
    conn().execute(sql)
    registration_tuple = conn().fetchone()
    registration = to_dict(registration_fields, registration_tuple)

    # Then, get attributes

    sql = """SELECT Attributter.Name AS Name, Attribut.id as id,
                    Attribut.Virkning AS Virkning FROM Attributter, Attribut 
                    WHERE
                        Attribut.AttributterID = Attributter.id AND
                        Attributter.RegistreringsID = {0} AND
                        TIMESTAMPTZ '{1}' <@ (Attribut.Virkning).TimePeriod
          """.format(registration['id'], application_time)
    conn().execute(sql)

    attributter = []
    for attr in conn().fetchall():
        attribut = to_dict(attributter_fields, attr)
        # Now extract field values
        sql = """SELECT name, value FROM ATTRIBUTFELT WHERE AttributID = {0}
              """.format(attribut['id'])
        conn().execute(sql)
        for name, value in conn().fetchall():
            attribut[name] = value
        attributter.append(attribut)

    registration['attributter'] = attributter
    print registration

    
    # Now, get states

    # TODO: Do this

    # And relations! 

    # TODO: Get relations




if __name__ == '__main__':

    read_object('28fdab2f-79c1-4535-9c37-9a0e77965ebb',
                application_time=datetime(2015, 1, 10))
