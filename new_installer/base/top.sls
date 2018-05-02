base:
  "*":
    - tasks.create_venv
    - tasks.install_database
    - tasks.install_oio_rest_api