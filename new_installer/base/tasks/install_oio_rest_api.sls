# Import grains created by the task runner
# Config variables are called with config.<variable>
# E.g. config["hostname"] is expressed with config.hostname
{% set config = grains["mox_config"] %}

install_dependencies_for_oio_rest:
  pkg.installed:
    - pkgs:
      - python-virtualenv
      - libxmlsec1-dev
      - swig
      - postgresql-common
      - libpq-dev
      - python-dev
      - libapache2-mod-wsgi
      - build-essential


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


# This should work for both Python 2 & 3
install_oio_rest_requirements:
  virtualenv.managed:
    - name: {{ config.virtualenv }}
    - system_site_packages: False
    - user: {{ config.user }}
    - requirements: {{ config.base_dir }}/oio_rest_api/requirements.txt


install_gunicorn:
  virtualenv.managed:
    - name: {{ config.virtualenv }}
    - system_site_packages: False
    - user: {{ config.user }}
    - pip_pkgs:
      - gunicorn

deploy_service_file:
  file.managed:
    - name: /etc/systemd/system/oio_rest_api.service
    - source: salt://files/oio_rest_api.service.j2
    - user: root
    - group: root
    - mode: 600
    - template: jinja
    - context:
        service_description: "OIO Rest interface"
        user: {{ config.user }}
        group: {{ config.group }}
        working_directory: {{ config.base_dir }}/oio_rest_api
        gunicorn: {{ config.virtualenv }}/bin/gunicorn
        workers: 4
        bind_address: 127.0.0.1:8080
        access_log: /var/log/oio_access.log
        error_log: /var/log/oio_error.log


enable_and_reload_oio_rest_service:
  service.running:
    - name: oio_rest_api
    - enable: True
    - reload: True