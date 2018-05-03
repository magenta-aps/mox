# Import grains created by the task runner
# Config variables are called with config.<variable>
# E.g. config["hostname"] is expressed with config.hostname
{% set config = grains["mox_config"] %}

update_postgresql_configuration:
  file.managed:
    - name: /etc/postgresql/9.5/main/pg_hba.conf
    - source: salt://files/pg_hba.conf.j2
    - user: postgres
    - group: postgres
    - mode: 644
    - template: jinja
    - context:
        db_user: {{ config.db.user }}


# Install pg_amqp - Postgres AMQP extension
# We depend on a specific fork, which supports setting of
# message headers
# https://github.com/duncanburke/pg_amqp.git
clone_repository_for_pg_amqp_extension:
  git.latest:
    - name: https://github.com/magenta-aps/pg_amqp.git
    - target: /tmp/pg_amqp
    - branch: master


compile_extension:
  cmd.run:
    - name: make install -C /tmp/pg_amqp PG_CONFIG=$PG_CONFIG
    - runas: root
    - env:
      - PG_CONFIG: /usr/lib/postgresql/9.5/bin/pg_config


# Apply changes
restart_postgresql:
  module.run:
    - name: service.restart
    - m_name: postgresql


enable_postgresql:
  service.running:
    - name: postgresql
    - enable: True
