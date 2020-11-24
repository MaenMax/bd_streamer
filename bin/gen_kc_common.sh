#!/bin/sh

#
# Fetch kc_common and compile the required version to populate the local maven cache
# in ${HOME}/.m2/repository/com/kaiostech/kc_common/${KC_COMMON_JAR_VERSION}/kc_common-${KC_COMMON_JAR_VERSION}.jar
#
# Usage:
# gen_kc_common.sh {version}
#
# Examples:
# gen_kc_common.sh 1.0.1
# gen_kc_common.sh v1.0.1
#
version=$1

if [ "x" = "x${version}" ]; then
	echo >&2 "[ERROR] Missing version as parameter! Aborting ..."
	exit 1
fi

# Verifying version form. 
# We will build the Pure Version (just the version) and the V Version (prefixed with v)
if [[ "${version}" =~ ^[0-9] ]]; then
	p_version="${version}"
	v_version="v${version}"
elif [[ "${version}" =~ ^v[0-9] ]]; then
	p_version=`echo ${version} | cut -b 2-`
	v_version="${version}"
else
	echo >&2 "[ERROR] Malformed version format: '$version'. Aborting ..."
	exit 2
fi

# JAR file is using pure version (without the v).
JAR_FILE="${HOME}/.m2/repository/com/kaiostech/kc_common/${p_version}/kc_common-${p_version}.jar"

if [ -f "${JAR_FILE}" ]; then
	echo "File '${JAR_FILE}' already found in Maven cache! Skipping generation ..."
	exit 0
fi

echo "Generating missing '${JAR_FILE}' ..."

thedate=`date +'%Y%m%d'`
thetime=`date +'%H%M%S'`

tmp_dir=`mktemp -d`

# Schedule a job to automatically delete the temporary folder
# where the signed archive  will be found as result of execution.
# NOTE: we use 20 min to let the client safely download the git 
#       repository on a slow connection.
echo "rm -Rf $tmp_dir" | at -m now +20 minute 2>/dev/null

echo "Cloning kc_common_java from https://git.kaiostech.com/cloud/kc_common_java in ${tmp_dir} ..."

{ cd ${tmp_dir} && git clone https://git.kaiostech.com/cloud/kc_common_java.git && cd kc_common_java; } || { echo >&2 "Failed to clone repository! Aborting ..."; exit 3; }

git checkout ${v_version} || { echo >&2 "Failed to checkout version ${version}! Aborting ..."; exit 4; }

make || { echo >&2 "[ERROR] Compilation failed. Aborting installation."; exit 5; }

# Verifying the presence of the archive in Maven cache.
if [ ! -f "${JAR_FILE}" ]; then
	echo >&2 "[ERROR] The archive '${JAR_FILE}' cannot be found despite successful compilation! Aborting ..."
	exit 6
fi

rm -Rf ${tmp_dir}


echo "Generation of '${JAR_FILE}' succeeded ..."
