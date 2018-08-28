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

# Apply changes
restart_postgresql:
  module.run:
    - name: service.restart
    - m_name: postgresql


enable_postgresql:
  service.running:
    - name: postgresql
    - enable: True
