#!/bin/ksh
#MENU_DESCRIPTION=AMC full control
#===============================================================
# NAME      :  AmcTools.ksh
# Programmer:  Pedro Pavan
# Date      :  14-Nov-14
# Purpose   :  AMC full control
#
# Changes history:
#
#  Date     |     By        | Changes/New features
# ----------+---------------+-------------------------------------
# 11-14-14	  Pedro Pavan     	Initial version
# 11-19-14	  Pedro Pavan     	URL
#===============================================================

MAIN_HOST="indlin3662"

######################################
# Usage
######################################
Usage() {
    EXIT_CODE=$1

    echo -e "\nUsage:\n"
    echo "$(basename $0) start|stop|restart|status|url|log"
    echo ""
    exit ${EXIT_CODE}
}

######################################
# AMC installation check
######################################
Amc_Check() {

	if [ -z "${AMC_HOME}" ]; then
		echo "AMC is currently not installed!"
		exit 2
	fi
}

######################################
# AMC start
######################################
Amc_Start() {
	${AMC_HOME}/bin/Amc Start
}

######################################
# AMC stop
######################################
Amc_Stop() {
	${AMC_HOME}/bin/Amc Stop
}

######################################
# AMC start
######################################
Amc_Restart() {
	${AMC_HOME}/bin/Amc Stop
	${AMC_HOME}/bin/Amc Start
}

######################################
# AMC status
######################################
Amc_Status() {
	DAEMON_PROCESS="DAMC_CONNECT"
	STATUS=$(pgrep -U ${USER} -f "${DAEMON_PROCESS}")

	if [ -z ${STATUS} ]; then
		echo "DOWN"
	else
		echo "UP  "
	fi
}

######################################
# AMC url
######################################
Amc_Url() {
	echo "http://${MAIN_HOST}:$(egrep 'amc.port' ${AMC_HOME}/config/AmcSystem.properties | cut -d '=' -f 2)"
}

######################################
# AMC log
######################################
Amc_Log() {
	less +F ${AMC_HOME}/logs/amc-out.log
}

######################################
# Main
######################################

[ $# -ne 1 ] && Usage 1
ACTION=$1

case ${ACTION} in
	"start")	Amc_Start	;;
	"stop")		Amc_Stop	;;
	"restart")	Amc_Restart	;;
	"status")	Amc_Status	;;
	"url")		Amc_Url		;;
	"log")		Amc_Log		;;
	*)			Usage 3		;;
esac

exit 0
