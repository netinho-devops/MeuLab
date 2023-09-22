#!/bin/ksh

cd ~/JEE/OMS/scripts/OmsDomain/OmsServer
STATUS=`./pingOmsServer.sh`

if [ "${STATUS}" == "UP" ]
then
 cd ~/JEE/OMS/scripts/OmsDomain/OmsServer
 ./forceStopOmsServer.sh
fi

 cd ~/JEE/OMS/WLS/OmsDomain/servers/OmsServer
 rm -rf logs tmp cache


cd ~/JEE/OMS/scripts/OmsClient/OMS_SmartClient
STATUS=`./pingOMS_SmartClient.sh`

if [ "${STATUS}" == "UP" ]
then
  cd ~/JEE/OMS/scripts/OmsClient/OMS_SmartClient
  ./forceStopOMS_SmartClient.sh

fi
 cd ~/JEE/OMS/WLS/OmsClient/servers/OMS_SmartClient
 rm -rf logs tmp cache

echo "OMS WL Stopped and Cache Cleaned"

