#!/bin/ksh
#MENU_DESCRIPTION=Remove OMS to AUA integration (Online)
###########################################
# Name: runBridgeSimulation.ksh
# Disable OMS to AUA integration (Online)
#
# Programmer: Antonio Ideguchi (hantonio)
###########################################

if [[ $USER == *"oms"* ]]
then
OMS_HOST=${MYHOST}
OMS_PORT=${WL_PORT}
OMS_USER="Jeeadmin"
OMS_PASS="Jeeadmin1"

OMS_CONN="t3://${OMS_HOST}:${OMS_PORT}"

WLST_PATH="${WL_HOME}/common/bin/"
WLST="wlst.sh"

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

echo "Removing AUA <> OMS integration..."

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

echo "OMS Host: ${OMS_HOST}"
echo "OMS Port: ${OMS_PORT}"
echo "OMS User: ${OMS_USER}"
echo "OMS Pasword: ${OMS_PASS}"
echo "OMS Connection: ${OMS_CONN}"

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

${WLST_PATH}${WLST} oms2aua-bridgecreation.py -u ${OMS_USER} -p ${OMS_PASS} -c ${OMS_CONN}

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

${WLST_PATH}${WLST} oms2aua-bridgesimulation.py -u ${OMS_USER} -p ${OMS_PASS} -c ${OMS_CONN} 

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
else
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "ERROR: Please run this script from OMS work account since it is a OMS related script!"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
fi
 
