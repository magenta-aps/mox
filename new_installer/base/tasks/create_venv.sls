# Import grains created by the task runner
# Config variables are called with {{ config.<variable> }}
# E.g. config["hostname"] is expressed with {{ config.hostname }}
{% set config = grains["mox_config"] %}

create_python_3_venv:
  cmd.run:
    - name: /usr/bin/env python3 -m venv {{ config.virtualenv }}