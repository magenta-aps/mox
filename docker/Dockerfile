# SPDX-FileCopyrightText: 2019-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

################################################################################
# Changes to this file requires approval from Labs. Please add a person from   #
# Labs as required approval to your MR if you have any changes.                #
################################################################################

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
ENV PYTHONUNBUFFERED=1 \
    MOX_SYSTEM_CONFIG_PATH=/code/docker/docker-settings.toml \
    MOX_USER_CONFIG_PATH=/user-settings.toml


WORKDIR /code/
COPY docker/sys-requirements.txt sys-requirements.txt
# hadolint ignore=DL3008,DL4006
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
  && apt-get -y install --no-install-recommends "$(grep -Eo '^(\w|-)+' sys-requirements.txt | paste -sd ' ')" \
  # clean up after apt-get and man-pages
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/man/?? /usr/share/man/??_* \
  # oio_rest expects some files and directories to be there. We create them with
  # the proper user and group.
  # /var/mox is default for file upload
  && install -g mox -o mox -d /var/mox \
  && install -g mox -o mox -d /log


# Create volumes for file upload and logs
VOLUME /var/mox
VOLUME /log


# Install requirements
COPY oio_rest/requirements.txt /code/oio_rest/requirements.txt
COPY oio_rest/requirements-test.txt /code/oio_rest/requirements-test.txt
COPY oio_rest/requirements-lint.txt /code/oio_rest/requirements-lint.txt
RUN pip3 install \
  -r oio_rest/requirements.txt \
  -r oio_rest/requirements-test.txt \
  -r oio_rest/requirements-lint.txt


# Copy and install application.
COPY dev-environment/settings-for-mo-test.toml ./dev-environment/settings-for-mo-test.toml
COPY docker ./docker
COPY oio_rest ./oio_rest
COPY README.rst .
COPY LICENSE .
# Install the application as editable. This makes it possible to mount `/code`
# to your host and edit the files during development.
# hadolint ignore=DL3013
RUN pip3 install -e oio_rest


# Run the server as the mox user on port 8080
USER mox:mox
EXPOSE 8080
ENTRYPOINT ["/code/docker/docker-entrypoint.sh"]
CMD ["gunicorn", \
  "--config", "/code/docker/gunicorn-settings.py", \
  "oio_rest:app"]
