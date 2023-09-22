#!/bin/ksh
#############################################################################################################################################
# AmcDayCheck.ksh This script check if amc is down and start it
# 
#
# Author - Avik Shtrum.
# December 2010
#############################################################################################################################################
export ScriptName=`basename $0`
export ScriptDir=`dirname $0`
echo $ScriptName
echo $ScriptDir

export SCRIPT_DIR=`cd $( dirname $0 ); pwd`
. ${HOME}/.profile > /dev/null 2>&1
cd $HOME

LogFile=${HOME}/CrontabLogs/AmcCheck.log
if [ ! -d ${HOME}/CrontabLogs ]
then
    mkdir -p ${HOME}/CrontabLogs
fi    
touch $LogFile

Date=`date '+%Y%m%d%H%M'`
echo "Start running at $Date" | tee -a $LogFile
#Tiger_List=`echo "set pages 0;\nset feed off;\nselect TIGER from all_tigers_details where unix_user is not NULL and Team='${Team}';" | sqlplus -s $DB`

   Host=`hostname` 
   
#if [ -d ${HOME}/Amc-${Host}/config ]
#then
#     AMCDIR=${HOME}/Amc-${Host}/config
#else
#     AMCDIR=${HOME}/Amc-${Host}/amc/config
#fi       

AMCDIR=`grep AMC_HOME ~/.profile | cut -d'=' -f2`/config   

   Port=`cat ${AMCDIR}/AmcSystem.properties | grep amc.port | awk -F= '{print $2}'`
   User=$LOGNAME 
   echo "netstat -na | grep $Port | grep LISTEN | wc -l | sed -e 's/^ *//'"
   Amc_Status=`netstat -na | grep $Port | grep LISTEN | wc -l | sed -e 's/^ *//'`     
        
   echo "Amc_Status=$Amc_Status" | tee -a $LogFile

   if [ "$Amc_Status" -ge 1 ] 
    then
         echo "Amc $Host - $User is up $Amc_Status" | tee -a $LogFile
    else
         Date1=`date '+%Y%m%d%H%M%S'`
         Amc Restart | tee -a $LogFile
         sleep 20
         Amc_Status=`netstat -na | grep $Port | grep LISTEN | wc -l | sed -e 's/^ *//'`
         if [ "$Amc_Status" -ge 1 ]
           then
               echo "Amc $Host $User Started successfully" | tee -a $LogFile
           else
               echo "Failed to start Amc $Host $User" | tee -a $LogFile
         fi
    fi
Date=`date '+%Y%m%d%H%M'`    
echo " End running at $Date "  | tee -a $LogFile
