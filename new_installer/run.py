# -- coding: utf-8 --

import json
from client import caller


# Apply state
execute_tasks = caller.cmd("state.apply")

for task, result in execute_tasks.items():
    formatted = json.dumps(result, indent=2)
    print(formatted)

