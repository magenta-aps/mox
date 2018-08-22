# Import grains created by the task runner
# Config variables are called with config.<variable>
# E.g. config["hostname"] is expressed with config.hostname
{% set config = grains["mox_config"] %}

ensure_that_rabbit_mq_is_installed:
  pkg.installed:
    - name: rabbitmq-server


ensure_that_rabbit_mq_is_running:
  service.running:
    - name: rabbitmq-server


# This should work for both Python 2 & 3
install_python_agents_requirements:
  virtualenv.managed:
    - name: {{ config.virtualenv }}
    - system_site_packages: False
    - user: {{ config.user }}
    - requirements: {{ config.base_dir }}/python_agents/notification_service/requirements.txt


Deploy notification service file:
  file.managed:
  - name: /etc/systemd/system/notification.service
  - source: salt://files/notification.service.j2
  - user: root
  - group: root
  - mode: 600
  - template: jinja
  - context:
      SERVICE_DESCRIPTION: "PgnotifyToAmqp Service"
      SERVICE_USER: {{ config.user }}
      SERVICE_GROUP: {{ config.group }}
      DB_NAME: {{ config.db.name }}
      DB_USER: {{ config.db.user }}
      DB_PASS: {{ config.db.pass }}
      DB_HOST: {{ config.db.host }}
      WORKING_DIR: {{ config.base_dir }}/python_agents/notification_service
      EXEC_START: {{ config.python_exec }} notify_to_amqp_service.py


ensure_that_notification_service_is_running:
  service.running:
    - name: notification