#!/bin/bash

# Finding out the current script directory and name out of how we have been called
SCRIPT_DIR=`dirname $0`
SCRIPT_NAME=`basename $0;`

# Building the ABSOLUTE diretory path regardless of the eventual symbolic links 
# so that we can always find our configuration files.
BASE_DIR_REL=`dirname $SCRIPT_DIR`

BASE_DIR=`cd ${BASE_DIR_REL}; pwd`
BIN_DIR=${BASE_DIR}/bin
CONF_DIR=${BASE_DIR}/conf


# Make sure foreign language characters are encoded correctly
export LANG="en_US.UTF-8"
export JAVA_HOME=/data/tools/repository/java

if [ ! -f ${BIN_DIR}/service_functions.sh ]; then
    echo "Cannot source missing ${BIN_DIR}/service_functions.sh. Aborting ..."
    exit 1
fi

. ${BIN_DIR}/service_functions.sh

layer=$1
exec_name=

if [ "x${layer}" = "x" ]; then
    echo "${BIN_NAME}: Layer name ('dl, dl3') should be provided as parameter! Aborting ..."
    exit 2
fi

case "$layer" in

    dl3) exec_name="${BIN_DIR}/run_bd_streamer_dl3.sh --config=${CONF_DIR}/bd_streamer.conf"
        ;;

    *) echo "${SCRIPT_NAME}: Unrecognized layer name '$layer'! Aborting ..."
        exit 3
        ;;
esac

if [ -f "${2}" ]; then

    # Nodes running on the cloud require this file to be present for security purposes.
    exec_name="${exec_name} --key_file=${2}"

elif [ -n "$(type -t Create_Key_Json)" ] && [ "$(type -t Create_Key_Json)" = function ]; then

    # Get the key file ready ahead of bootstrapping the node for local dev users.
    key_filename="keys_${layer}.json"
    rm -f "${key_filename}"
    Create_Key_Json | Create_File "${key_filename}"
    exec_name="${exec_name} --key_file=${key_filename}"
fi

pid=`start_process $layer "$exec_name"`

if [ $? -ne 0 ]; then
    echo "Failed: ${pid}"
else
    echo "Success: Service $layer started with PID $pid"
fi
