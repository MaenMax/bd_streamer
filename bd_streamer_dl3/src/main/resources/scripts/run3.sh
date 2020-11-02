#!/bin/bash

# Ensure foreign language character encoding works properly
export LANG="en_US.UTF-8"

current_rel_dir=`dirname $0`

. ${current_rel_dir}/functions.sh || { echo "[ERROR] Failed to find ${current_rel_dir}/functions.sh! Aborting ..."; exit 1; }

abs_tool_dir=`cd ${current_rel_dir}; pwd`
abs_base_dir=`dirname ${abs_tool_dir}`

CONF_PATH=${current_rel_dir}/conf:${abs_base_dir}/conf

if [ -d ${current_rel_dir}/jars ]; then
    DEP_JARS=`append_jars_from_path ${current_rel_dir}/jars`
elif  [ -d ${abs_base_dir}/jars ]; then
    DEP_JARS=`append_jars_from_path ${abs_base_dir}/jars`
else
    echo "[ERROR] Cannot find JARS directory for dependencies ..."
    exit 1
fi

CUMULIS_JAR=`ls ${current_rel_dir}/kc_fin_fe_dl3-*.jar`

ADDONS="/data/tools/repository/java/jre/lib/tools.jar:/contrib/capacity-scheduler/*.jar"

CLASSPATH=${CUMULIS_JAR}:${CONF_PATH}:${abs_base_dir}:${DEP_JARS}:${ADDONS}


if [ "x${JAVA_HOME}" = "x" ]; then
    echo >&2 "[WARNING] JAVA_HOME environment variable not defined."
else
    if [ -d ${JAVA_HOME}/jre/lib/amd64/server ]; then
        export LD_LIBRARY_PATH=${JAVA_HOME}/jre/lib/amd64/server
        #echo "LD_LIBRARY_PATH set to '${LD_LIBRARY_PATH}'"
    elif [ -d ${JAVA_HOME}/lib/amd64/server ]; then
        export LD_LIBRARY_PATH=${JAVA_HOME}/lib/amd64/server
        #echo "LD_LIBRARY_PATH set to '${LD_LIBRARY_PATH}'"
    else 
        echo "[WARNING] Failed to find path of libjvm.so"
        echo "[WARNING] LD_LIBRARY_PATH not set."
    fi
fi

java -Xms128m -Xmx4g -XX:MetaspaceSize=512m -cp ${CLASSPATH}  "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
