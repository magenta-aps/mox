# Import grains created by the task runner
# Config variables are called with config.<variable>
# E.g. config["hostname"] is expressed with config.hostname
{% set config = grains["mox_config"] %}

# This should work for both Python 2 & 3
install_oio_rest_requirements:
  virtualenv.managed:
    - name: {{ config.virtualenv }}
    - system_site_packages: False
    - pip_pkgs:
      - {{ config.base_dir }}/oio_rest
      - gunicorn


deploy_service_file:
  file.managed:
    - name: /etc/systemd/system/oio_rest.service
    - source: salt://files/oio_rest.service.j2
    - user: root
    - group: root
    - mode: 600
    - template: jinja
    - context:
        service_description: "OIO REST web application"
        name: oio_rest
        user: {{ config.user }}
        group: {{ config.group }}
        working_directory: {{ config.base_dir }}/oio_rest
        gunicorn: {{ config.virtualenv }}/bin/gunicorn
        socket_path: /run/oio_rest/socket

deploy_socket_file:
  file.managed:
    - name: /etc/systemd/system/oio_rest.socket
    - source: salt://files/oio_rest.socket.j2
    - user: root
    - group: root
    - mode: 600
    - template: jinja
    - context:
        service_description: "OIO REST socket"
        name: oio_rest
        user: {{ config.user }}
        group: www-data
        socket_path: /run/oio_rest/socket


undeploy_ubuntu_nginx_site:
  file.absent:
    - name: /etc/nginx/sites-enabled/default


deploy_nginx_site:
  service.running:
    - name: nginx
    - enable: True
    - reload: True
  file.managed:
    - name: /etc/nginx/sites-enabled/oio_rest
    - source: salt://files/nginx.j2
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
        http_port: {{ config.http_port }}
        https_port: {{ config.https_port }}
        ssl_certificate: {{ config.ssl_certificate or '' }}
        ssl_certificate_key: {{ config.ssl_certificate_key or '' }}
        socket_path: /run/oio_rest/socket


enable_and_reload_oio_rest:
  service.running:
    - name: oio_rest
    - enable: True
    - reload: True
