# SPDX-FileCopyrightText: 2021- Magenta ApS
# SPDX-License-Identifier: MPL-2.0

from functools import lru_cache
from typing import Optional

from pydantic import BaseSettings


class Settings(BaseSettings):
    """
    These settings can be overwritten by environment variables
    The environement variable name is the upper-cased version of the variable name below
    E.g. DB_NAME == db_name
    """

    db_name: str = "mox"
    db_user: str = "mox"
    db_password: str
    db_host: str = "mox-db"
    db_port: str = "5432"
    sslmode: Optional[str]

    # Prefix for all relative URLs. A value of "/MyOIO" will result in API
    # endpoints such ``http://example.com/MyOIO/organisation/organisationenhed``.
    base_url: str = ""

    # Path to DB_STRUCTURE extensions
    db_extensions_path: Optional[str]

    # If enabled, expose /testing/db-* endpoint for setup, reset and teardown of a
    # test database. Useful for integration tests from other components such as MO.
    # Does not work when running multi-threaded.
    testing_api: bool = False

    # If enabled, exposes /db/truncate endpoint, for truncating the current
    # database.
    truncate_api: bool = False

    # The log level for the Python application
    lora_log_level: str = "WARNING"

    # If enabled, uses alternative search implementation
    quick_search: bool = True

    # Whether authorization is enabled.
    # If not, the restrictions module is not called.
    enable_restrictions: bool = False


@lru_cache()
def get_settings():
    return Settings()
