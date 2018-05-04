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