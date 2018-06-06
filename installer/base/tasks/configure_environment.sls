# Import grains created by the task runner
# Config variables are called with config.<variable>
# E.g. config["hostname"] is expressed with config.hostname
{% set config = grains["mox_config"] %}

install_system_dependencies:
  pkg.installed:
    - pkgs:

      # SYSTEM
      - build-essential
      - libxmlsec1-dev
      - ca-certificates
      - software-properties-common
      - nginx

      # POSTGRESQL
      - postgresql
      - postgresql-common
      - postgresql-client
      - postgresql-server-dev-all
      - postgresql-contrib
      - postgresql-9.5-pgtap

      # AMQP
      - rabbitmq-server


create_account_group:
  group.present:
    - name: {{ config.group }}
    - system: True

create_account_user:
  user.present:
    - name: {{ config.user }}
    - gid: {{ config.group }}
    - groups:
        - {{ config.group }}
    - home: {{ config.base_dir }}
    - system: True


create_upload_directory:
  file.directory:
    - name: /var/mox
    - user: {{ config.user }}
    - group: {{ config.group }}
    - dir_mode: 755
    - file_mode: 644


create_log_directory:
  file.directory:
    - name: /var/log/mox
    - user: {{ config.user }}
    - group: {{ config.group }}
    - dir_mode: 755
    - file_mode: 644

create_audit_log_file:
  file.touch:
    - name: /var/log/mox/audit.log


set_audit_log_file_permissions:
  file.managed:
    - name: /var/log/mox/audit.log
    - user: {{ config.user }}
    - group: {{ config.group }}
    - mode: 644
