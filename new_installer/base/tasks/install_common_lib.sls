# Import grains created by the task runner
# Config variables are called with config.<variable>
# E.g. config["hostname"] is expressed with config.hostname
{% set config = grains["mox_config"] %}

# For most installations
# AVA requires a different lib
install_common_lib:
  cmd.run:
    - name: {{ config.virtualenv }}/bin/pip install {{ config.base_dir }}/lib/common