Operating LoRa MOX
==================

It is the intention that mox is run by gunicorn behind a reverse proxy such as
nginx.

As the primary bottleneck is the connection between mox and its' database, you
can make the application accept connections faster by scaling the number
gunicorn workers. Use more workers and use the sync worker class.
