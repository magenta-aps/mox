# We do not use alpine. The resulting image is smaller, but there is currently
# no support for pip installation of wheels (binary) packages. It falls back
# to installing from source which is very time consuming. See
# https://github.com/pypa/manylinux/issues/37 and
# https://github.com/docker-library/docs/issues/904
FROM python:3.5


LABEL org.opencontainers.image.title="MOX - Messaging Service and Actual State Database" \
      org.opencontainers.image.vendor="Magenta ApS" \
      org.opencontainers.image.licenses="MPL-2.0" \
      org.opencontainers.image.documentation="https://mox.readthedocs.io" \
      org.opencontainers.image.source="https://github.com/magenta-aps/mox"


# Force the stdout and stderr streams from python to be unbuffered. See
# https://docs.python.org/3/using/cmdline.html#cmdoption-u
ENV PYTHONUNBUFFERED 1


WORKDIR /code/
# ATTENTION DEVELOPER: When you change these prerequisites, make sure to also
# update them in doc/user/installation.rst
RUN set -ex \
  # Add a mox group and user. Note: this is a system user/group, but have
  # UID/GID above the normal SYS_UID_MAX/SYS_GID_MAX of 999, but also above the
  # automatic ranges of UID_MAX/GID_MAX used by useradd/groupadd. See
  # `/etc/login.defs`. Hopefully there will be no conflicts with users of the
  # host system or users of other docker containers.
  #
  # See `doc/user/installation.rst` for instructions on how to overwrite this.
  && groupadd -g 72010 -r mox\
  && useradd -u 72010 --no-log-init -r -g mox mox \
  # Install dependencies
  && apt-get -y update \
  && apt-get -y install --no-install-recommends \
    # git is needed for python packages with `… = {git = …}` in requirements.txt.
    # It pulls a lot of dependencies. Maybe some of them can be ignored.
    git \
    # Python packages dependencies:
    # for xmlsec.
    libxmlsec1-dev \
  # clean up after apt-get and man-pages
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/man/?? /usr/share/man/??_* \
  # oio_rest expects some files and directories to be there. We create them with
  # the proper user and group.
  # /var/mox is default for FILE_UPLOAD_FOLDER
  && install -g mox -o mox -d /var/mox


# Create volume for file upload
VOLUME /var/mox


# Install requirements
COPY oio_rest/requirements.txt /code/oio_rest/requirements.txt
RUN pip3 install -r oio_rest/requirements.txt


# Copy and install application.
COPY docker-entrypoint.sh .
COPY oio_rest ./oio_rest
COPY README.rst .
COPY LICENSE .
# Install the application as editable. This makes it possible to mount `/code`
# to your host and edit the files during development.
RUN pip3 install -e oio_rest


# Run the server as the mox user on port 8080
USER mox:mox
EXPOSE 8080
ENTRYPOINT ["/code/docker-entrypoint.sh"]
CMD ["gunicorn", "-b", "0.0.0.0:8080", "oio_rest.app:app"]
