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


install_oio_rest_requirements:
  pip.installed:
    - requirements: {{ config.base_dir }}/oio_rest_api/requirements.txt


install_gunicorn:
  pip.installed:
    - name: gunicorn


deploy_service_file:
  file.managed:
    - name: /etc/systemd/system/oio_rest.service
    - source: salt://files/service_template.j2
    - user: root
    - group: root
    - mode: 600
    - template: jinja
    - context:
        service_description: This should be the output
        user: {{ config.user }}
        group: {{ config.group }}
        startup_script: {{ config.virtualenv }}/bin/gunicorn -w 4 -b :8080

    - defaults:
        after_requirement: False
        after_value: None


enable_and_reload_oio_rest_service:
  service.running:
    - name: oio_rest
    - enable: True
    - reload: True