#!/bin/env ksh
#===============================================================
# NAME      :  checkWebLogicLog.ksh
# Programmer:  Rajkumar Nayeni
# Date      :  12-Apr-16
# Purpose   :  Check whether WL Server came up without exception
#
# Changes history:
#
#  Date     |    By           | Changes/New features
# ----------+-----------------+-------------------------------------
# 04-12-16    Rajkumar Nayeni   Initial version
# 04-12-16    Eitan Corech      Initial version
# 01-06-17    Pedro Pavan	    Show more details
# 01-18-17    Pedro Pavan	    Support WSF
#===============================================================

# EXIT CODE
# 1	 = Wrong parameter
# 2  = Server is down
# 4	 = Log file was not found
# 8	 = No information available
# 16 = Server is still starting
# 32 = Found exceptions

checkExceptions()
{
		cd ${logLocation}
		
		grep -ni "${startupMessage}" $logFile | tail -1 | cut -d':' -f1 | read firstline
		grep -ni "${endMessage}"     $logFile | tail -1 | cut -d':' -f1 | read lastline
		grep     "${endMessage}"     $logFile | tail -1 | cut -d'<' -f2 | cut -d">" -f1 | read cameuptime

		if [ "${firstline}" = "" ]
		then
		   echo "$LogFile file is overridden for ${serverName}. No information about the startup time."
		   exit 8
		fi
		
		if [ "${lastline}" = "" ] || [ "${firstline}" -gt "${lastline}" ]  
		then
	 		echo "Server still coming up..."
			exit 16
		fi
		 
		exceptioncount=$(sed -n ${firstline},${lastline}p $logFile | egrep -c "${ErrorMsg}")

		if [ "${exceptioncount}" = 0 ] 
		then
			 if [ "${PRODUCT}" == "wsf" ]; then
			 	cameuptime=$(echo ${cameuptime} | awk '{ print $1" "$2 }')
			 fi

		     echo "Server ${serverName} came up fine at ${cameuptime} without exceptions"
			 exit 0
		else
		     echo "Server ${serverName} came up with error at ${cameuptime}, please check logs!"
			 echo "Error Messages:"
			 sed -n ${firstline},${lastline}p $logFile | egrep "${ErrorMsg}" | sort | uniq
			 echo ""
			 exit 32
		fi
}


###############################################################################
#
#	MAIN 
#
###############################################################################

PRODUCT=$(echo ${USER} | sed 's/viv//g' | sed 's/trn//g' | sed 's/wrk//g' | tr -d '[0-9]')
unixUserName="${USER}"
startupMessage='Server state changed to STARTING'
endMessage='RUNNING mode'
ErrorMsg="Caused By|Exception:"

case $PRODUCT in 
		abp)
              logLocation=${HOME}/JEE/ABPProduct/logs/ABP-FULL/ABPServer
              scriptLocation=${HOME}/JEE/ABPProduct/scripts/ABP-FULL
              pingScript=pingABPServer.sh
              logFile=`ls -1 ${logLocation}/weblogic.*.log 2> /dev/null | tail -1`
              serverName=ABP
              ;;
        crm)
              logLocation=${HOME}/JEE/CRMProduct/logs/CRMDomain/CRMServer
              scriptLocation=${HOME}/JEE/CRMProduct/scripts/CRMDomain/CRMServer
              pingScript=pingCRMServer.sh
              logFile=`ls -1 ${logLocation}/weblogic.*.log 2> /dev/null | tail -1`
              serverName=CRM
              ;;
        oms)
              logLocation=${HOME}/JEE/OMS/logs/OmsDomain/OmsServer
              scriptLocation=${HOME}/JEE/OMS/scripts/OmsDomain/OmsServer
              pingScript=pingOmsServer.sh
              logFile=`ls -1 ${logLocation}/weblogic*.log 2> /dev/null | tail -1`
              serverName=OMS
              ;;
        ams|amss|mcss|mcs)
              logLocation=${HOME}/JEE/AMSSProduct/logs/AMSSFullDomain/AMSSFullServer
              scriptLocation=${HOME}/JEE/AMSSProduct/scripts/AMSSFullDomain/AMSSFullServer
              pingScript=pingAMSSFullServer.sh
              logFile=`ls -1 ${logLocation}/weblogic.*.log 2> /dev/null | tail -1`
              serverName=AMSS
              ;;
		omni|omn)
			  logLocation=${HOME}/JEE/LightSaberDomain/logs/LightSaberDomain/omni_LSJEE
			  scriptLocation=${HOME}/JEE/LightSaberDomain/scripts/LightSaberDomain/omni_LSJEE
			  pingScript=pingomni_LSJEE.sh
			  logFile=`ls -1 ${logLocation}/weblogic.*.log 2> /dev/null | tail -1`
			  serverName=OMNI
			  ;;
		wsf)
			  logLocation=${HOME}/deployment/WSF/apache-tomcat/apache-tomcat-a/logs
			  scriptLocation=/vivnas/viv/vivtools/Scripts
			  pingScript=wsf_ping
			  logFile=`ls -1 ${logLocation}/wsf.log 2> /dev/null | tail -1`
			  serverName=WSF
			  startupMessage="Root WebApplicationContext: initialization started"
			  endMessage="Root WebApplicationContext: initialization completed in"
              ErrorMsg="ERROR"
			  ;;
     	*)
              echo "Seems like you didn't execute the script from right location"
           	  echo "This script is for checking WebLogic startup logs of ABP, CRM, OMS, AMSS, OMNI, WSF only and must be executed from the env"
              exit 1
              ;;
esac

if [ "$(${scriptLocation}/${pingScript})" == *"DOWN"* ]; then
	echo "Server is DOWN, Please make it up and run it again"
    exit 2
fi

if [ ! -f ${logFile} ]; then
	echo "${logLocation}/${logFile} is not present "
    exit 4
fi

checkExceptions 
