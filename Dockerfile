# We do not use alpine. The resulting image is smaller, but there is currently
# no support for pip installation of wheels (binary) packages. It falls back
# to installing from source which is very time consuming. See
# https://github.com/pypa/manylinux/issues/37 and
# https://github.com/docker-library/docs/issues/904
FROM python:3.5

# Force the stdout and stderr streams from python to be unbuffered. See
# https://docs.python.org/3/using/cmdline.html#cmdoption-u
ENV PYTHONUNBUFFERED 1

WORKDIR /code/


# ATTENTION DEVELOPER: When you change these prerequisites, make sure to also
# update them in doc/user/installation.rst
RUN set -ex \
  # Add a mox group and user. Note: this is a system user/group, but have
  # UID/GID above the normal SYS_UID_MAX/SYS_GID_MAX of 999.
  && groupadd -g 1141 -r mox\
  && useradd -u 1141 --no-log-init -r -g mox mox \
  # Install dependencies
  && apt-get -y update \
  && apt-get -y install --no-install-recommends \
    # git is needed for python packages with `… = {git = …}` in requirements.txt.
    # It pulls a lot of dependencies. Maybe some of them can be ignored.
    git \
    # psql is used in docker-entrypoint.sh to check for db availability.
    postgresql-client \
    # Python packages dependencies:
    # for xmlsec.
    libxmlsec1-dev \
  # clean up after apt-get and man-pages
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/man/?? /usr/share/man/??_* \
  # oio_rest expects some files and directories to be there. We create them with
  # the proper user and group.
  # /var/mox is default for FILE_UPLOAD_FOLDER
  && install -g mox -o mox -d /var/mox \
  # /var/log/mox/audit.log is default for AUDIT_LOG_FILE
  && install -g mox -o mox -d /var/log/mox

# Create volumes for file upload and logs
VOLUME /var/mox /var/log/mox

# Install requirements
COPY oio_rest/requirements.txt /code/oio_rest/requirements.txt
RUN pip3 install -r oio_rest/requirements.txt

# Copy application code to the container.
COPY docker-entrypoint.sh .
COPY oio_rest ./oio_rest
COPY README.rst .
COPY LICENSE .

# Install the application as editable. This makes it possible to mount `/code`
# to your host and edit the files during development.
RUN pip3 install -e oio_rest

USER mox:mox

EXPOSE 5000

ENTRYPOINT ["/code/docker-entrypoint.sh"]

CMD ["gunicorn", "-b", "0.0.0.0:5000", "oio_rest.app:app"]
