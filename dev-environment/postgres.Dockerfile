# Install pgtap atop of the offical postgres docker image. pgtap is used for
# unittesting. This file should not be used in production.

FROM magentaaps/postgres-os2mo:9.6.15-1
RUN apt-get update \
  && apt-get  -y install --no-install-recommends postgresql-$PG_MAJOR-pgtap \
  # clean up after apt-get and man-pages
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/man/?? /usr/share/man/??_*
