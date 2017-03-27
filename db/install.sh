#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/config.sh
WIPE_DB=0
LOGFILE="$DIR/install.log"

echo "Installing database dependencies"
(
    echo
    date
    echo
    sudo apt-get -y install --no-install-recommends  $(cat "$DIR/SYSTEM_DEPENDENCIES")
) >> "$LOGFILE" 2>&1

# Install pg_amqp - Postgres AMQP extension
# We depend on a specific fork, which supports setting of
# message headers
# https://github.com/duncanburke/pg_amqp.git
echo "Installing PostreSQL AMQP extension"
(
    echo
    date
    echo
    set -x

    for PG_CONFIG in /usr/lib/postgresql/*/bin/pg_config
    do
        rm -rf /tmp/pg_amqp
        git clone https://github.com/magenta-aps/pg_amqp.git /tmp/pg_amqp
        echo $PG_CONFIG
        sudo make install -C /tmp/pg_amqp PG_CONFIG=$PG_CONFIG
        rm -rf /tmp/pg_amqp
    done
) >> "$LOGFILE" 2>&1

if sudo -u postgres psql -c "\\connect $MOX_DB" > /dev/null 2>&1
then
    echo "Database '$MOX_DB' already exists in PostgreSQL"
else
	# Install Database
    echo "Installing database"
    (
        echo
        date
        echo
        set -x

        # Install pgtap - unit test framework
        sudo pgxn install pgtap

        echo "Updating authentication config"
        # Set authentication method to 'md5' (= password, not peer)
        sudo sed -i -r 's/local\s+all\s+all\s+peer/local   all             all                                     trust/g' /etc/postgresql/*/main/pg_hba.conf
        sudo sed -i -r 's/host\s+all\s+all\s+127.0.0.1\/32\s+md5/#host    all             all             127.0.0.1\/32            md5/g' /etc/postgresql/*/main/pg_hba.conf
        sudo sed -i -r 's/host\s+all\s+all\s+::1\/128\s+md5/#host    all             all             ::1\/128                 md5/g' /etc/postgresql/*/main/pg_hba.conf

        sudo service postgresql restart

	    $DIR/initdb.sh >> "$LOGFILE"
    ) >> "$LOGFILE" 2>&1
fi
