# Import grains created by the task runner
# Config variables are called with config.<variable>
# E.g. config["hostname"] is expressed with config.hostname
{% set config = grains["mox_config"] %}

# This should work for both Python 2 & 3
install_oio_rest_requirements:
  virtualenv.managed:
    - name: {{ config.virtualenv }}
    - system_site_packages: False
    - user: {{ config.user }}
    - requirements: {{ config.base_dir }}/oio_rest/requirements.txt


install_gunicorn:
  virtualenv.managed:
    - name: {{ config.virtualenv }}
    - system_site_packages: False
    - user: {{ config.user }}
    - pip_pkgs:
      - gunicorn


deploy_service_file:
  file.managed:
    - name: /etc/systemd/system/oio_rest.service
    - source: salt://files/oio_rest_api.service.j2
    - user: root
    - group: root
    - mode: 600
    - template: jinja
    - context:
        service_description: "OIO Rest interface"
        user: {{ config.user }}
        group: {{ config.group }}
        working_directory: {{ config.base_dir }}/oio_rest
        gunicorn: {{ config.virtualenv }}/bin/gunicorn


enable_and_reload_oio_rest:
  service.running:
    - name: oio_rest
    - enable: True
    - reload: True