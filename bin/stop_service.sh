#!/bin/bash

# Finding out the current script directory and name out of how we have been called
SCRIPT_DIR=`dirname $0`
SCRIPT_NAME=`basename $0`

if [ ! -f ${SCRIPT_DIR}/service_functions.sh ]; then
    echo "Cannot source missing ${SCRIPT_DIR}/service_functions.sh. Aborting ..."
    exit 1
fi

. ${SCRIPT_DIR}/service_functions.sh

layer=$1
exec_name=

if [ "x${layer}" = "x" ]; then
    echo "${SCRIPT_NAME}: Layer name ('dl') should be provided as parameter! Aborting ..."
    exit 2
fi

case "$layer" in

    dl3) exec_name=${SCRIPT_DIR}/run_bd_streamer_dl3.sh
        ;;

    *) echo "${SCRIPT_NAME}: Unrecognized layer name '$layer'! Aborting ..."
        exit 3
        ;;
esac

pid=`stop_process $layer $exec_name`

if [ $? -ne 0 ]; then
    echo "Failed: ${pid}"
else
    echo "Success: stopped $layer (${pid})"
fi
