# -- coding: utf-8 --

import os
from salt import client
from salt import config

# log file
log_file = "install.log"

# Installer directory
installer_dir = os.path.dirname(
    os.path.abspath(__file__)
)

# Path to config
salt_config = os.path.join(installer_dir, "salt.conf")

# Import salt config
__opts__ = config.minion_config(salt_config)

# Set file roots (relative to rootdir)
salt_base = os.path.join(installer_dir, "base")

__opts__['file_roots'] = {
    "base": [
        salt_base
    ]
}

# Minion caller client
# This used in a masterless configuration
caller = client.Caller(mopts=__opts__)

# Helper functions
def simple_log(text, log_file=log_file):
    """
    Simple function to create an install log file

    :param text:        Text value to log
    :param log_file:    Name/full path to the log file
    """

    with open(log_file, "w") as log:
        log.write(text + "\n")


def notify_and_log(executed_tasks):
    """
    Example:

    {
      "comment": "Created empty file /var/log/mox/audit.log",
      "name": "/var/log/mox/audit.log",
      "start_time": "13:28:14.853353",
      "changes": {
        "new": "/var/log/mox/audit.log"
      },
      "result": true,
      "__id__": "create_audit_log_file",
      "__run_num__": 5,
      "duration": 0.852,
      "__sls__": "tasks.configure_environment"
    }

    :param executed_tasks:  Return value (Type: dict)

    :return:
    """

    if type(executed_tasks) is not dict:
        return

    for id, task in executed_tasks.items():
        # Map dict
        task_id = task.get("__id__")
        task_result = task.get("result")
        task_duration = task.get("duration")
        task_comment = task.get("comment")
        task_changes = task.get("changes")

        if task_result:
            result = "ok"
        else:
            result = "not ok"

        # ID
        print("""
        Task:   {id}
        Time:   {duration}
        Result: {result}
        """.format(
            id=task_id,
            duration=task_duration,
            result=resul
        ))

        # Log task
        simple_log(task_id)

        # Log comment
        simple_log(task_comment)

        # Include changes in the log file
        include_changes = ["diff", "stdout"]

        for change in include_changes:
            content = task_changes[change]

            simple_log(content)
