import psycopg2

# TODO: Fix hard-coded connection params!!!!
conn = psycopg2.connect(
    database='mox',
    user='mox',
    password='mox',
    host='localhost')

curs = conn.cursor()
conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
curs.execute("SELECT * FROM pg_catalog.pg_tables where tablename like '%registrering'")
rows = curs.fetchall()
for row in rows:
    query = ("create trigger notify_{0} after insert or update or delete on {0} " +
             "for each row execute procedure notify_event();").format(row[1])
    try:
        curs.execute(query)
    except:
        print(query)
