#!/bin/ksh
###########################################################
# Created by : <unsure about original author>
# Updated by : Ricardo Gesuatto #10-Apr-15 # portability and use on NET
# Requires : newMarkAsDeployed.class
# Comments : Required class is based on the HotFix Tool API classes
# Syntax : HotfixMarkAs.ksh <hotFixID> <product> <version> <env>
# Example : HotfixMarkAs.ksh 600041603 ABP 8300 99
###########################################################

# Usage
if [ $# -ne 4 ]; then
	echo "Usage : $(basename $0) <HF_ID> <Product> <Version> <Environment>"
	exit 1
fi

# CLI parameters
hf_ids=$1
selected_prod=$2
selected_ver=$3
selected_env=$4

# AMC API user, so we can invoke the HotFix Tool
AmcCurrentUser="ApiAdmin"

# Just so we can set the Java Environment
export ENVIRON="PATH=${PATH},"

# Directory where our scripts (and the needed .class) are located
mydir=`dirname "$0"`

export CLASSPATH=${AMC_CLASSPATH}:${mydir}
export CLASSPATH=${CLASSPATH}:${MON_CONFIG_DIR}
export CLASSPATH=${CLASSPATH}:${MON_LIB_DIR}/amc-core.jar
export CLASSPATH=${CLASSPATH}:${MON_LIB_DIR}/log4j.jar

cd ${mydir}

${JAVA_HOME}/bin/java -Xms256m -Xmx1024m \
    -classpath ${CLASSPATH} \
    -DHOST="${HOST}" \
    -DENVIRON="${ENVIRON}" \
    -DAMC_HOME="${AMC_HOME}" \
    -Damdocs.system.home="${UAMS_SYS_HOME}" \
    -Damdocs.security.root="${UAMS_SYS_HOME}" \
    -Damdocs.uams.config.resource="${UAMS_CONFIG_RESOURCE}" \
    -Damdocs.uams.startup.password="${UAMS_STARTUP_PASSWD}" \
    -Damdocs.messageHandling.home="${UAMS_SYS_HOME}" \
    -DAMC_APACHE_HOME="${AMC_APACHE_HOME}" \
    -DMON_BIN_DIR="${MON_BIN_DIR}" \
    -DMON_XML_DIR="${MON_XML_DIR}" \
    -DMON_CONFIG_DIR="${MON_CONFIG_DIR}" \
    -DMON_LOG_DIR="${MON_LOG_DIR}" \
    -Duser.timezone="${USER_TIMEZONE}" \
    -Dfile.encoding="UTF-8" \
    -cp ${AMC_CLASSPATH}:${MON_CONFIG_DIR}:${MON_LIB_DIR}/amc-core.jar:${MON_LIB_DIR}/log4j.jar \
         newMarkAsDeployed $hf_ids $AmcCurrentUser $selected_prod $selected_ver $selected_env 2>/dev/null
    
STATUS=$?

echo "Hotfix Mark As Deployed Finished with status: ${STATUS}"
exit ${STATUS}
