# Import grains created by the task runner
# Config variables are called with config.<variable>
# E.g. config["hostname"] is expressed with config.hostname
{% set config = grains["mox_config"] %}

# This should work for both Python 2 & 3
install_python_agents_requirements:
  virtualenv.managed:
    - name: {{ config.virtualenv }}
    - system_site_packages: False
    - user: {{ config.user }}
    - requirements: {{ config.base_dir }}/python_agents/requirements.txt


# Setup log files
create_mox_advis_log_file:
  file.touch:
    - name: /var/log/mox/mox-advis.log

set_mox_advis_log_file_permissions:
  file.managed:
    - name: /var/log/mox/mox-advis.log
    - user: {{ config.user }}
    - group: {{ config.group }}
    - mode: 644

create_mox_elk_log_file:
  file.touch:
    - name: /var/log/mox/mox-elk.log

set_mox_elk_log_file_permissions:
  file.managed:
    - name: /var/log/mox/mox-elk.log
    - user: {{ config.user }}
    - group: {{ config.group }}
    - mode: 644


ensure_that_rabbit_mq_is_installed:
  pkg.installed:
    - name: rabbitmq-server

ensure_that_rabbit_mq_is_running:
  service.running:
    - name: rabbitmq-server


deploy_mox_advis_service:
  file.managed:
    - name: /etc/systemd/system/mox_advis.service
    - source: salt://files/mox_agents.service.j2
    - user: root
    - group: root
    - mode: 600
    - template: jinja
    - context:
        service_description: "Mox Advis Service"
        user: {{ config.user }}
        group: {{ config.group }}
        working_directory: {{ config.base_dir }}/python_agents
        exec_start: {{ config.python_exec }} mox_advis.py
        after_service: rabbitmq-server.service
    - require:
      - ensure_that_rabbit_mq_is_running

deploy_mox_elk_log_service:
  file.managed:
    - name: /etc/systemd/system/mox_elk_log.service
    - source: salt://files/mox_agents.service.j2
    - user: root
    - group: root
    - mode: 600
    - template: jinja
    - context:
        service_description: "Mox Elk Log Service"
        user: {{ config.user }}
        group: {{ config.group }}
        working_directory: {{ config.base_dir }}/python_agents
        exec_start: {{ config.python_exec }} mox_elk_log.py
        after_service: rabbitmq-server.service
    - require:
      - ensure_that_rabbit_mq_is_running
