#!/bin/sh

#
# Parse the provided POM.xml file in the parameter and search what version of kc_common is required and return it on STDOUT.
#
# Usage:
# extract_kc_common_version_from_pom.sh {POM FILE PATH}
#

#
POM_FILE=$1

if [ "x" = "x${POM_FILE}" ]; then
	echo >&2 "[ERROR] Missing pom file path as parameter! Aborting ..."
	exit 1
fi

if [ ! -f "${POM_FILE}" ]; then
	echo >&2 "[ERROR] Provided POM File ${POM_FILE} cannot be found! Aborting ..."
	exit 2
fi

version=$(cat ${POM_FILE} | sed s/\"//g | sed s/\'//g | xargs -- echo  | grep -Po '<dependency>\s*<groupId>com.kaiostech</groupId>\s*<artifactId>kc_common</artifactId>\s*<version>[^<]*</version>' | grep -Po '<version>[^<]*</version>' | sed 's/<[^>]*>//g')

if [ $? -ne 0 ]; then
	echo >&2 "[ERROR] Failed to extract version from ${POM_FILE}! Aborting ..."
	exit 3	
fi
echo $version
