#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


sudo -u postgres createuser mox

# Install pgtap - unit test framework
sudo pgxn install pgtap

# Install pg_amqp - Postgres AMQP extension
# We depend on a specific fork, which supports setting of message headers
# https://github.com/duncanburke/pg_amqp.git
git clone https://github.com/duncanburke/pg_amqp.git /tmp/pg_amqp
cd /tmp/pg_amqp && sudo make install
rm -rf /tmp/pg_amqp

# Set authentication method to 'md5' (= password, not peer)
sed -i 's/local   all             all                                     peer/local   all             all                                     md5/g' /etc/postgresql/9.3/main/pg_hba.conf
