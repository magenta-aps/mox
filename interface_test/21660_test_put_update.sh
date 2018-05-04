#!/bin/bash

# Test configuration
DIR=$(dirname ${BASH_SOURCE[0]})
source $DIR/config.sh

result=$(curl -k -H "Content-Type: application/json" -X POST -d "$(cat test_data/facet_opret.json)" $HOST_URL/klassifikation/facet)
uuid=$(expr "$result" : '.*"uuid": "\([^"]*\)"')
echo $uuid
curl -i -k -H "Content-Type: application/json" -X PUT -d "$(cat test_data/facet_reduce_effective_time_21660.json)" $HOST_URL/klassifikation/facet/$uuid
