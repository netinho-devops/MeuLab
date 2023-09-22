#!/bin/ksh

cd ~/JEE/CRMProduct/scripts/CRMDomain/CRMServer
STATUS=`./pingCRMServer.sh`


if [ "${STATUS}" == "UP" ]
then

  cd ~/JEE/CRMProduct/scripts/CRMDomain/CRMServer
  ./forceStopCRMServer.sh
  sleep 5
fi

 cd ~/JEE/CRMProduct/WLS/CRMDomain/servers/CRMServer
 rm -rf logs tmp cache




cd ~/JEE/CRMProduct/scripts/SmartClientDomain/SmartClientServer
STATUS=`./pingSmartClientServer.sh`

if [ "${STATUS}" == "UP" ]
then
  cd ~/JEE/CRMProduct/scripts/SmartClientDomain/SmartClientServer
  ./forceStopSmartClientServer.sh

fi

 cd ~/JEE/CRMProduct/WLS/SmartClientDomain/servers/SmartClientServer
 rm -rf logs tmp cache


echo "CRM WL Stopped and cache Cleaned"


