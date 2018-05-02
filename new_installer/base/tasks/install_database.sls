# Import grains created by the task runner
# Config variables are called with config.<variable>
# E.g. config["hostname"] is expressed with config.hostname
{% set config = grains["mox_config"] %}

install_system_dependencies:
  pkg.installed:
    - pkgs:
      - ca-certificates
      - postgresql
      - postgresql-client
      - postgresql-server-dev-all
      - postgresql-contrib
      - python-jinja2
      - rabbitmq-server
      - git
      - build-essential

      # Extension
      - postgresql-9.5-pgtap


update_postgresql_configuration:
  file.managed:
    - name: /etc/postgresql/9.5/main/pg_hba.conf
    - source: salt://files/pg_hba.conf.j2
    - user: root
    - group: root
    - mode: 600
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


enable_and_reload_postgresql:
  service.running:
    - name: postgresql
    - enable: True
    - reload: True


run_database_init_script:
  cmd.run:
    - name: ./initdb.sh
    - cwd: {{ config.base_dir }}/db
    - env:
      - BASE_DIR: {{ config.base_dir }}
      - DB_DIR: {{ config.base_dir }}/db
      - PYTHON_EXEC: {{ config.python_exec }}

      # DB
      - SUPER_USER: {{ config.db.superuser }}
      - MOX_DB_HOST: {{ config.db.host }}
      - MOX_DB: {{ config.db.name }}
      - MOX_DB_USER: {{ config.db.user }}
      - MOX_DB_PASSWORD: {{ config.db.pass }}

      # AMQP
      - MOX_AMQP_HOST: {{ config.amqp.host }}
      - MOX_AMQP_PORT: {{ config.amqp.port }}
      - MOX_AMQP_USER: {{ config.amqp.user }}
      - MOX_AMQP_PASS: {{ config.amqp.pass }}
      - MOX_AMQP_VHOST: {{ config.amqp.vhost }}