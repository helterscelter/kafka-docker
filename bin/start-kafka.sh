#!/bin/bash

if [[ -z "$KAFKA_ADVERTISED_HOST_NAME" && -n "$HOSTNAME_COMMAND" ]]; then
    export KAFKA_ADVERTISED_HOST_NAME=$(eval $HOSTNAME_COMMAND)
fi

# evaluate the configuration template to set run-time settings before launching kafka
# the config will be passed as a parameter to this script
/usr/bin/template.sh $1.template $1
$KAFKA_HOME/bin/kafka-server-start.sh $*
