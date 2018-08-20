import time
import select
import psycopg2

# TODO: Fix hard-coded connection params!!!!
conn = psycopg2.connect(
    database='mox',
    user='mox',
    password='mox',
    host='localhost')

curs = conn.cursor()
while True:
    time.sleep(1)
    print('Sleeping')
    curs.execute("LISTEN events;")
    print(conn.notifies)
    conn.poll()
    conn.commit()
    while conn.notifies:
        notify = conn.notifies.pop(0)
        print("Got NOTIFY:", notify.pid, notify.channel, notify.payload)
