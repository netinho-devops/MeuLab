#!/bin/ksh

cd ~/JEE/ABPProduct/scripts/ABP-FULL
STATUS=`./pingABPServer.sh`

if [ "${STATUS}" == "UP" ]
then

   cd ~/JEE/ABPProduct/scripts/ABP-FULL
  ./forceStopABPServer.sh
sleep 5
 
echo "delete from TABLE_BPM_LM_SERVER;" |   sqlplus $APP_DB_USER/$APP_DB_PASS@$APP_DB_INST
echo "delete from TABLE_BPM_LM_CONNECTION;" |   sqlplus $APP_DB_USER/$APP_DB_PASS@$APP_DB_INST
echo "commit;" |   sqlplus $APP_DB_USER/$APP_DB_PASS@$APP_DB_INST
  

fi  
   cd ~/JEE/ABPProduct/WLS/ABP-FULL/servers/ABPServer
   rm -rf logs tmp cache data

echo 'ABP WL Stopped and cache Cleaned'


