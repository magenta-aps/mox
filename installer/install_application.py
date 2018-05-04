# -- coding: utf-8 --

from client import caller
from client import notify_and_log


# Run states
print("## Configuring environment ##")
configure = caller.cmd("state.apply", "tasks.configure_environment")
notify_and_log(configure)

print("## Setup database (postgresql) ##")
install_database = caller.cmd("state.apply", "tasks.install_database")
notify_and_log(install_database)

print("## Install/Setup database ##")
install_oio_rest = caller.cmd("state.apply", "tasks.install_oio_rest")
notify_and_log(install_oio_rest)

print("## Initializing database ##")
init_db = caller.cmd("state.apply", "tasks.initialize_database")
notify_and_log(init_db)