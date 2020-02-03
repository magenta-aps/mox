# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

"""
    settings.py
    ~~~~~~~~~~~

    This module contains all global ``oio_rest`` settings.

    The variables available and their defaults are defined in
    ``default-settings.toml``. Furthermore, $MOX_SYSTEM_CONFIG_PATH and
    $MOX_USER_CONFIG_PATH can be used to point at other config files.

    The config file precedens is
        default-settings.toml < $MOX_SYSTEM_CONFIG_PATH < $MOX_USER_CONFIG_PATH

    default-settings.toml: reference file and default values.
    $MOX_SYSTEM_CONFIG_PATH: configuration for system environment e.g. docker.
    $MOX_USER_CONFIG_PATH: this is the file where you write your configuration.
"""

import logging
import os
import sys

import toml


logger = logging.getLogger(__name__)


def read_config(config_path):
    try:
        with open(config_path) as f:
            content = f.read()
    except FileNotFoundError as err:
        logger.critical("%s: %r", err.strerror, err.filename)
        sys.exit(5)
    try:
        return toml.loads(content)
    except toml.TomlDecodeError:
        logger.critical("Failed to parse TOML")
        sys.exit(4)


def update_config(configuration, new_settings):
    # we cannot just do dict.update, because we do not want to "polute" the
    # namespace with anything in *new_settings*, just the variables defined in
    # **configuration**.
    for key in new_settings:
        if key in configuration:
            if isinstance(configuration[key], dict):
                update_config(configuration[key], new_settings[key])
            else:
                configuration[key] = new_settings[key]
        else:
            logger.warning("Invalid key in config: %s", key)


base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
default_settings_path = os.path.join(base_dir, "oio_rest", "default-settings.toml")
with open(default_settings_path, "r") as f:
    # DO NOT print or log ``config`` as it will EXPOSE the PASSWORD
    config = toml.load(f)

system_config_path = os.getenv("MOX_SYSTEM_CONFIG_PATH", False)
user_config_path = os.getenv("MOX_USER_CONFIG_PATH", False)
if system_config_path:
    logger.info("Reading system config from %s", system_config_path)
    update_config(config, read_config(system_config_path))
if user_config_path:
    logger.info("Reading user config from %s", user_config_path)
    update_config(config, read_config(user_config_path))


# All these variables are kept for backward compatibility / to change the least
# code. From now on, use the ``config`` object in this module. At this point,
# it would be fine to go through the code and get rid of the old variables,
# although it might be non-trivial, especially for the test suite.

BASE_URL = config["base_url"]

DB_HOST = config["database"]["host"]
DB_PORT = config["database"]["port"]
DB_USER = config["database"]["user"]
DB_PASSWORD = config["database"]["password"]
DATABASE = config["database"]["db_name"]

SAML_AUTH_ENABLE = config["saml_sso"]["enable"]
SAML_IDP_METADATA_URL = config["saml_sso"]["idp_metadata_url"]
SAML_IDP_INSECURE = config["saml_sso"]["idp_insecure"]
SAML_REQUESTS_SIGNED = config["saml_sso"]["requests_signed"]
SAML_KEY_FILE = config["saml_sso"]["key_file"]
SAML_CERT_FILE = config["saml_sso"]["cert_file"]
SQLALCHEMY_DATABASE_URI = config["saml_sso"]["sqlalchemy_uri"]
SESSION_PERMANENT = config["saml_sso"]["session_permanent"]
PERMANENT_SESSION_LIFETIME = config["saml_sso"]["permanent_session_lifetime"]

DO_ENABLE_RESTRICTIONS = config["restrictions"]["enable"]
AUTH_RESTRICTION_MODULE = config["restrictions"]["module"]
AUTH_RESTRICTION_FUNCTION = config["restrictions"]["function"]

LOG_AMQP_SERVER = config["audit_log"]["host"]
MOX_LOG_EXCHANGE = config["audit_log"]["exchange"]
MOX_LOG_QUEUE = config["audit_log"]["queue"]
LOG_IGNORED_SERVICES = config["audit_log"]["ignored_services"]

FILE_UPLOAD_FOLDER = config["file_upload"]["folder"]
