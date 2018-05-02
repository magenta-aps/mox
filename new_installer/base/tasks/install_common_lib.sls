# Import grains created by the task runner
# Config variables are called with config.<variable>
# E.g. config["hostname"] is expressed with config.hostname
{% set config = grains["mox_config"] %}

# For most installations
# AVA requires a different lib
install_common_lib_python_2:
  pip.installed:
    - name:
      - pkg: {{ config.base_dir }}/lib/common
      - bin_env: {{ config.virtualenv }}
    - user: