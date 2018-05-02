# -- coding: utf-8 --

import json
from client import caller


def print_task(executed_tasks):
    for task, result in executed_tasks.items():
        formatted = json.dumps(result, indent=2)
        print(formatted)


# Run states
create_venv = caller.cmd("state.apply", "tasks.create_venv")
print_task(create_venv)

install_common_lib = caller.cmd("state.apply", "tasks.install_common_lib")
print_task(install_common_lib)

install_database = caller.cmd("state.apply", "tasks.install_database")
print_task(install_database)

install_oio_rest_api = caller.cmd("state.apply", "tasks.install_oio_rest_api")
print_task(install_oio_rest_api)
