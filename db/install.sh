#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/config.sh
WIPE_DB=0
LOGFILE="$DIR/install.log"

echo "Installing database dependencies"
sudo apt-get -qq install --no-install-recommends  $(cat "$DIR/SYSTEM_DEPENDENCIES")

if [ ! -z $ALWAYS_CONFIRM ]; then
	WIPE_DB=1
else
	if [[ (! -z `command -v psql`) && (! -z `sudo -u postgres psql -Atqc "\list $MOX_DB"`) ]]; then
		echo "Database $MOX_DB already exists in PostgreSQL"
		read -p "Do you want to overwrite it? (y/n): " -n 1 -r
		echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			WIPE_DB=1
		fi
	else
		echo "DB does not exist!"
		WIPE_DB=1
	fi
fi

if [ $WIPE_DB == 1 ]; then
	# Install Database
	echo "" > "$LOGFILE"

    # Install pgtap - unit test framework
    sudo pgxn install pgtap

    # Install pg_amqp - Postgres AMQP extension
    # We depend on a specific fork, which supports setting of message headers
    # https://github.com/duncanburke/pg_amqp.git
    git clone https://github.com/duncanburke/pg_amqp.git /tmp/pg_amqp
    pushd /tmp/pg_amqp
    sudo make install >> "$LOGFILE"
    popd
    rm -rf /tmp/pg_amqp

    echo "Updating authentication config"
    # Set authentication method to 'md5' (= password, not peer)
    sudo sed -i -r 's/local\s+all\s+all\s+peer/local   all             all                                     trust/g' /etc/postgresql/9.3/main/pg_hba.conf
    sudo sed -i -r 's/host\s+all\s+all\s+127.0.0.1\/32\s+md5/#host    all             all             127.0.0.1\/32            md5/g' /etc/postgresql/9.3/main/pg_hba.conf
    sudo sed -i -r 's/host\s+all\s+all\s+::1\/128\s+md5/#host    all             all             ::1\/128                 md5/g' /etc/postgresql/9.3/main/pg_hba.conf

    sudo service postgresql restart

	$DIR/recreatedb.sh >> "$LOGFILE"
fi
