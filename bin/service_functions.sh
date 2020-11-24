#!/bin/bash

function start_process
{
    # Layer name is always the first parameter.
    local layer="$1";
    shift
    
    # Executable name may be followed with flags and other parameters.
    # So only extracting the first word ...
    local proc_name=`echo $1 | cut - -d" " -f1`;

    # ... and assigning the rest to args.
    local arg1=`echo $1 | cut - -d" " -f2`
    local arg2=`echo $1 | cut - -d" " -f3`
    local arg3=`echo $1 | cut - -d" " -f4`

    LOGFILE=bd_streamer_${layer}.out
    PIDFILE=start_${layer}.pid

    if [ ! -e ${proc_name} ]; then
        echo "Cannot find executable '$proc_name'. Aborting ..."
        exit 5
    fi

    if [ -f ${PIDFILE} ]; then
        PID=`cat ${PIDFILE}`
        kill >/dev/null 2>&1 -0 ${PID} && { echo "Process already running with PID ${PID}. Aborting ..."; exit 6; }
    fi

    nohup 2>&1 "${proc_name}" "$arg1" "$arg2" "$arg3" >> "${LOGFILE}" 2>&1 &

    echo $! > "${PIDFILE}"
    echo "`cat ${PIDFILE}`"
}

Create_Key_Json() {


    printf '{"aws_user_arn": "%s",
        "aws_s3_minio_access_key": "%s",
        "aws_s3_minio_secret_key": "%s",
        "smpp_login": "%s",
        "smpp_password": "%s",
        "smtp_login": "%s",
        "smtp_password": "%s",
        "fcm_key": "%s",
        "aps_key": "%s",
        "hash_imei_secret": "%s",
        "cass_user": "%s",
        "cass_pw": "%s",
        "db_cryptokey": "%s",
        "psms_secret_key":"%s",
        "pw_dcb_secret_key":"%s",
        "pw_dcb_public_key":"%s",
        "pw_cc_api_key":"%s"
        }\n' \
        ${AWS_USER_ARN} ${AWS_ACCESS_KEY_ID} ${AWS_SECRET_ACCESS_KEY} \
        ${SMPP_LOGIN} ${SMPP_PASSWORD} ${SMTP_LOGIN} ${SMTP_PASSWORD} \
        ${FCM_KEY} ${APS_KEY} ${HASH_IMEI_SECRET} \
        ${CASS_USER} ${CASS_PW} \
        ${DB_CRYPTOKEY} ${PSMS_SECRET_KEY} ${PW_DCB_PRIV_KEY} ${PW_DCB_PUB_KEY} ${PW_CC_API_KEY}

}


Create_File() {

    key_filename="${1}"

    if [ -f ${key_filename} ]
    then
        rm -f ${key_filename}
    fi

    echo "" > ${key_filename}
    chmod 600 ${key_filename}

    while read LINE; do
        echo $LINE >> ${key_filename}
    done < /dev/stdin
}

function stop_process
{
    thedate=`date +'%Y%m%d%H%M%S'`
    tmp_file="/tmp/stop_process_${thedate}"

    local layer="$1";
    local proc_name="$2";
    
    PIDFILE=start_${layer}.pid
    LOGFILE=bd_streamer_${layer}.out
    
    if [ ! -f ${PIDFILE} ]; then
        echo "Failed to find PID file '${PIDFILE}'. Process is likely not running."
        exit 5
    fi

   PID=`cat ${PIDFILE}`
    
   # Making sure the target process is existing and we have the authorization to kill it.
   # Redirecting the output to eventually analyze the reason of the failure.
   kill >${tmp_file} 2>&1 -0 ${PID}
   
   if [ $? -ne 0 ]; then
        # Here, we were not able to send a signal to the process. Either it doesn't exists, or we
        # don't have the permission to do so. We have to figure out by looking into the output.
        grep >/dev/null 2>&1 "No such process"  ${tmp_file}

        if [ $? -eq 0 ]; then
            # The process doesn't exists! Then we can delete the PID File.
            echo "Process with PID ${PID} not running . Aborting ..."; rm >/dev/null 2>&1 -f ${PIDFILE}; exit 6; 
        fi
        
        # If we reach here, there we are likely not permitted to kill the process! We have to keep the PIDFILE!
        msg="`cat ${tmp_file} | awk -F- '{ print $2 }'`"

        echo "Kill ${PID}: '$msg' . Aborting ..."; exit 6; 
    fi
    
    let "attempt=0"
    ok=0
    while [ $attempt -lt 30 ];
    do
        # Listing all process childs of top process given by PID  
        pid_list=`pstree -pn ${PID} | grep -o "([[:digit:]]*)"  | grep -o "[[:digit:]]*"`

        kill >/dev/null 2>&1 ${pid_list}

        sleep 1

        # Checking whether the process leader has properly been killed.
        kill >/dev/null 2>&1 -0 ${PID}

        if [ $? -ne 0 ]; then
            # Yes!
            ok=1
            break
        fi

        let "attempt=$attempt+1"
        echo -n "."
        
    done

    if [ $ok -eq 0 ]; then
        echo "Failed to kill one or several of the processes ${pid_list}. Aborting ..."
        exit 8
    fi

    rm >/dev/null 2>&1 -f ${PIDFILE}
    
    # Saving/cleaning logs
    logdir="${layer}-logs-${thedate}"
    mkdir >/dev/null 2>&1 ${logdir} && mv ${LOGFILE} bd_streamer_${layer}.log* ${logdir} 
    
    echo "${pid_list}"
}
