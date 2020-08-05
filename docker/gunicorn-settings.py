# SPDX-FileCopyrightText: 2019-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

################################################################################
# Changes to this file requires approval from Labs. Please add a person from   #
# Labs as required approval to your MR if you have any changes.                #
################################################################################

# Settings for gunicorn in docker.
import multiprocessing


bind = "0.0.0.0:8080"
workers = multiprocessing.cpu_count() * 2 + 1
worker_tmp_dir = "/dev/shm"

# Disable access log
# This parameters takes a filepath to a log file or a None value.
accesslog = None
