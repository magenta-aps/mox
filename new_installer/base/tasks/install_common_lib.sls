# Import grains created by the task runner
# Config variables are called with config.<variable>
# E.g. config["hostname"] is expressed with config.hostname
{% set config = grains["mox_config"] %}

install_common_lib_python_2:
  virtualenv.managed:
    - name: {{ config.virtualenv }}
    - system_site_packages: False
    - user: {{ config.user }}
    - pip_pkgs:
      - {{ config.base_dir }}/lib/common