# Import grains created by the task runner
# Config variables are called with config.<variable>
# E.g. config["hostname"] is expressed with config.hostname
{% set config = grains["mox_config"] %}

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