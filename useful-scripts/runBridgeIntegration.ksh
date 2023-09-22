#!/bin/ksh
#MENU_DESCRIPTION=Configure OMS to AUA Integration
###########################################
# Name: runBridgeIntegration.ksh 
# Integrates OMS to AUA receiving parameters as listed on usage function
#
# Programmer: Antonio Ideguchi (hantonio)
###########################################

if [ $# -ne 4 ]
then
	echo "ERROR: Incorrect number of parameters."
	echo "Usage: ${basename} AUA_HOST AUA_PORT AUA_USER AUA_PASS"
	exit 1
fi

if [[ $USER == *"oms"* ]]
then
AUA_HOST=$1
AUA_PORT=$2
AUA_USER=$3
AUA_PASS=$4

OMS_HOST=${HOSTNAME}
OMS_PORT=${WL_PORT}
OMS_USER="Jeeadmin"
OMS_PASS="Jeeadmin1"


AUA_CONN="t3://${AUA_HOST}:${AUA_PORT}"
OMS_CONN="t3://${OMS_HOST}:${OMS_PORT}"

WLST_PATH="${WL_HOME}/common/bin/"
WLST="wlst.sh"

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

echo "Starting AUA <> OMS Integration..."

echo "AUA Host: ${AUA_HOST}"
echo "AUA Port: ${AUA_PORT}"
echo "AUA User: ${AUA_USER}"
echo "AUA Pasword: ${AUA_PASS}"
echo "AUA Connection: ${AUA_CONN}"

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

echo "OMS Host: ${OMS_HOST}"
echo "OMS Port: ${OMS_PORT}"
echo "OMS User: ${OMS_USER}"
echo "OMS Pasword: ${OMS_PASS}"
echo "OMS Connection: ${OMS_CONN}"

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

${WLST_PATH}${WLST} oms2aua-bridgecreation.py -u ${OMS_USER} -p ${OMS_PASS} -c ${OMS_CONN}

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

echo "${WLST_PATH}${WLST} oms2aua-bridgeintegration.py -u ${OMS_USER} -p ${OMS_PASS} -c ${OMS_CONN} -j ${AUA_USER} -k ${AUA_PASS} -l ${AUA_CONN}"
${WLST_PATH}${WLST} oms2aua-bridgeintegration.py -u ${OMS_USER} -p ${OMS_PASS} -c ${OMS_CONN} -j ${AUA_USER} -k ${AUA_PASS} -l ${AUA_CONN}

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
else
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	echo "ERROR: Please run this script from OMS work account since it is a OMS related script!" 
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
fi
