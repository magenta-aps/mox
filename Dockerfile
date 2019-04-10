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
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/man/?? /usr/share/man/??_* \
  # oio_rest expects some files to be there. TODO: make it output to docker log
  && install -d /var/mox \
  && install -d /var/log/mox \
  && touch /var/log/mox/audit.log \
  && chown mox:mox /var/log/mox/audit.log

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


# We use the `mox` executable. It is created with setuptools
# `entry_point={'console_scripts': ['mox' = …]}` in `oio_rest/setup.py`. But it
# require that `.egg-info` is always updated. An outdated `.egg_info` can give
# you `DistributionNotFound` exception from `pkg_resources` because
# `oio_rest.egg_info/requires.txt` and `requirements.txt` is not in sync.
#
# We update it here to make sure it is included in the image. If you mount
# `/code` to your host, you need to update it manually.
RUN (cd oio_rest && python3 setup.py egg_info)

USER mox:mox

EXPOSE 5000

ENTRYPOINT ["/code/docker-entrypoint.sh"]

CMD ["gunicorn", "-b", "0.0.0.0:5000", "oio_rest.app:app"]
