# -- coding: utf-8 --

from client import caller

# Gather info
config = caller.cmd("grains.get", "mox_config")

if not config:
    raise RuntimeError(
        "No configuration available"
    )

# Map config
database_name = config["db"]["name"]
database_user = config["db"]["user"]

# Stop services
# NOTE: service names are hardcoded here
# TODO: service names should perhaps be added to the config module
stop_nginx = caller.cmd("service.stop", "nginx")
print("Stopping nginx: {}".format(stop_nginx))

stop_notification = caller.cmd("service.stop", "notification")
print("Stopping notification_service: {}".format(stop_notification))

# Remove database
remove_database = caller.cmd("postgres.db_remove", database_name)
print("Remove database: {}".format(remove_database))

# Remove database user
remove_database_user = caller.cmd("postgres.user_remove", database_user)
print("Remove database user: {0}".format(remove_database_user))

# Initdb
init_db = caller.cmd("state.apply", "tasks.initialize_database")

for task, output in init_db.items():

    # Map dict
    changes = output["changes"]
    stdout = changes["stdout"]
    stderr = changes["stderr"]
    result = output["result"]

    # Write stdout
    stdout_log = open("recreatedb.out","w+")
    stdout_log.write(stdout)

    # Write stderr
    error_log = open("recreatedb.err", "w+")
    error_log.write(stderr)

    # Print result
    print("Initialize database: {0}".format(result))


# Restart services
restart_nginx = caller.cmd("service.restart", "nginx")
print("Restarting nginx: {}".format(restart_nginx))

restart_notification = caller.cmd("service.restart", "notification")
print("Restarting notification_service: {}".format(restart_notification))