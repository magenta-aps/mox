# Import grains created by the task runner
# Config variables are called with config.<variable>
# E.g. config["hostname"] is expressed with config.hostname
{% set config = grains["mox_config"] %}

install_system_dependencies:
  pkg.installed:
    - pkgs:

      # SYSTEM
      - python-dev
      - python-jinja2
      - build-essential
      - libxmlsec1-dev
      - swig
      - libpq-dev
      - ca-certificates
      - git

      # POSTGRESQL
      - postgresql
      - postgresql-common
      - postgresql-client
      - postgresql-server-dev-all
      - postgresql-contrib
      - postgresql-9.5-pgtap

      # AMQP
      - rabbitmq-server


create_virtual_environment_for_application:
  virtualenv.managed:
    - name: {{ config.virtualenv }}
    - system_site_packages: False
    - user: {{ config.user }}


install_common_lib:
  virtualenv.managed:
    - name: {{ config.virtualenv }}
    - system_site_packages: False
    - user: {{ config.user }}
    - pip_pkgs:
      - {{ config.base_dir }}/lib/common
    - require:
      - create_virtual_environment_for_application


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
