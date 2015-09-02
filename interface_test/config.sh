URL=

if [ -z $HOST_URL ]
then

    HOST_URL="https://mox.magenta-aps.dk"

    if [ -z $1 ]
    then

        if [ -z $URL ]
        then

            read -p "Indtast URL, default $HOST_URL: " URL
        fi
    else
        URL=$1
    fi

    if [ ! -z $URL ]
    then
        # We got one
        HOST_URL=$URL
    fi
fi
