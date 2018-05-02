# -- coding: utf-8 --

# THIS IS A CONFIGURATION FILE FOR GUNICORN
# DEVELOPER DEFAULTS

import os

# wrapper
env = os.environ.get

# Location of access log file
accesslog= env("GUNICORN_ACCESS_LOG", "/tmp/oio_access.log")

# Location of error log file
errorlog = env("GUNICORN_ERROR_LOG", "/tmp/oio_error.log")

# Gunicorn log level
loglevel = env("GUNICORN_LOG_LEVEL", "warning")

# Bind address (Can be either TCP or Unix socket)
bind = env("GUNICORN_BIND_ADDRESS", '127.0.0.1:8080')

# Gunicorn workers
# Example:
#   workers = multiprocessing.cpu_count() * 2 + 1
# For more information, please see (# Please see http://docs.gunicorn.org/en/stable/configure.html)
workers = env("GUNICORN_WORKERS", 2)