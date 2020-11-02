#!/bin/sh


function append_jars_from_path
{
    local jar_base_dir="$1";
    local classpath="";
    local firstrun=1

    for jar in `ls $jar_base_dir/*.jar`
    do
	if [ "${firstrun}" = "1" ]; then
	    firstrun="0"
	else
	    classpath="${classpath}:"
	fi

	classpath="${classpath}$jar"

    done

    echo ${classpath}
}


function append_files_from_path
{
    local jar_base_dir="$1";
    local classpath="";
    local firstrun=1

    for jar in `ls $jar_base_dir/*`
    do
	if [ "${firstrun}" = "1" ]; then
	    firstrun="0"
	else
	    classpath="${classpath}:"
	fi

	classpath="${classpath}$jar"

    done

    echo ${classpath}
}



