#!/usr/bin/env python


import psycopg2

try:
    connection = psycopg2.connect(database='mox', user='mox')
    cur = connection.cursor()
    cur.execute('SELECT * FROM BRUGER')
    res = cur.fetchone()
    print res

except psycopg2.DatabaseError as e:
    print str(e)
    
