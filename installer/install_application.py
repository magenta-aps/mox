# -- coding: utf-8 --

import json
from client import caller


def print_task(executed_tasks):
    for task, result in executed_tasks.items():
        formatted = json.dumps(result, indent=2)
        print(formatted)


# Run states
configure = caller.cmd("state.apply", "tasks.configure_environment")
print_task(configure)

install_database = caller.cmd("state.apply", "tasks.install_database")
print_task(install_database)

install_oio_rest = caller.cmd("state.apply", "tasks.install_oio_rest")
print_task(install_oio_rest)

init_db = caller.cmd("state.apply", "tasks.initialize_database")
print_task(init_db)