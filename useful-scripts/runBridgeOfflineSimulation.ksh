#!/bin/ksh
#MENU_DESCRIPTION=Remove OMS to AUA integration (Offline)
###########################################
# Name: runBridgeSimulation.ksh
# Disable OMS to AUA integration (Offline)
#
# Programmer: Antonio Ideguchi (hantonio)
###########################################

if [[ $USER == *"oms"* ]]
then

WLST_PATH="${WL_HOME}/common/bin/"
WLST="wlst.sh"

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

echo "Removing AUA <> OMS integration..."

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

${WLST_PATH}${WLST} oms2aua-bridgesimulation-offline.py

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

else
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "ERROR: Please run this script from OMS work account since it is a OMS related script!"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
fi
 
