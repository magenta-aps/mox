# Import grains created by the task runner
# Config variables are called with config.<variable>
# E.g. config["hostname"] is expressed with config.hostname
{% set config = grains["mox_config"] %}

# Currently this task assumes that the dist is Ubuntu "Xenial"
add_java_8_repository:
  pkgrepo.managed:
    - humanname: Open Java JDK 8
    - name: deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu xenial main
    - dist: xenial
    - file: /etc/apt/sources.list.d/openjdk.list

  pkg.latest:
    - pkgs:
      - openjdk-8-jdk
      - maven
    - refresh: True


# Assuming 64bit arch type
build_java_modules:
  cmd.run:
    - name: mvn package --quiet -Dmaven.test.skip=true -Dmaven.clean.skip=true
    - cwd: {{ config.base_dir }}/agentbase/java
    - runas: mox
    - env:
      - JAVA_HOME: /usr/lib/jvm/java-8-openjdk-amd64
      - CMD_JAVA: /usr/bin/java
      - CMD_JAVAC: /usr/bin/javac

install_java_modules:
  cmd.run:
    - name: mvn org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file --quiet -Dfile=target/agent-1.0.jar -DgroupId=dk.magenta.mox -DartifactId=agent -Dversion=1.0 -Dpackaging=jar -DlocalRepositoryPath=$HOME/.m2/repository
    - cwd: {{ config.base_dir }}/agentbase/java
    - runas: mox
    - env:
      - JAVA_HOME: /usr/lib/jvm/java-8-openjdk-amd64
      - CMD_JAVA: /usr/bin/java
      - CMD_JAVAC: /usr/bin/javac


# THIS DOES NOT WORK
install_mox_rest_frontend_system_dependencies:
  pkg.installed:
    - pkgs:
      - maven
      - rabbitmq-server
      - python-dev
      - libffi-dev
      - libssl-dev

install_mox_rest_frontend:
  cmd.run:
    - name: {{ config.base_dir }}/agents/install.sh
    - runas: {{ config.user }}
    - env:
      - DOMAIN: {{ config.hostname }}

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