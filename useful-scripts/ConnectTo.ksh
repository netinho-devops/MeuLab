#!/bin/ksh
#===============================================================
# NAME      :  ConnectTo.ksh
# Programmer:  Pedro Pavan
# Date      :  18-Nov-15
# Purpose   :  Connect to environment using alias
#
# Changes history:
#
#  Date     |     By        | Changes/New features
# ----------+---------------+-----------------------------------
# 11-18-15    Pedro Pavan       Initial version
#===============================================================

######################################
# Usage
######################################
Usage() {
    EXIT_CODE=$1

    echo -e "Usage: \n"
    echo "$(basename $0) -e <env_number> -p <product_name> [-h]"
    echo ""
    echo "  -h   Display help		                "
	echo "  -e   Environment Number                 "
    echo "  -p   Product (ABP, CRM, OMS, EPC, MCS, SLO, SLA)	"
    echo ""

    exit ${EXIT_CODE}
}

######################################
# Site
######################################
Site() {
    echo "NA"
}

######################################
# Connect
######################################
Connect()
{
	CONNECTION_TRING=$(print "
        WHENEVER SQLERROR EXIT 5
        SET FEEDBACK OFF
        SET HEADING OFF
        SET PAGES 0
        SET LINE 500

		select distinct signature from ENSPOOL where product = '${PRODUCT}' and ENV_NUM = '${ENVIRONMENT}';
	" | sqlplus -S ${TOOLS_DB_USER}/${TOOLS_DB_PASSWORD}@${TOOLS_DB_INSTANCE})

	ssh ${CONNECTION_TRING} 

#	CONNECTIONS=$(echo ${CONNECTION_TRING} | wc -l)
#
#	case ${CONNECTIONS} in
#		0)	echo "Connection to ${PRODUCT}#${ENVIRONMENT} was not found!" ;; exit 1
#		1)	ssh ${CONNECTION_TRING} ;; exit 0
#		*)	echo -e "Many connections were found:\n${CONNECTION_TRING}" ;; exit 2
#	esac
}

######################################
# Main
######################################
cd ~/Scripts/environment/connect

while getopts ":e:p:h" opt
do 
    case "${opt}" in
        e) ENVIRONMENT=${OPTARG}	;;
		p) PRODUCT=${OPTARG}		;;
        h) Usage 0              	;;
        *) Usage 1              	;;
    esac
done

PRODUCT=$(echo ${PRODUCT} | tr '[a-z]' '[A-Z]')

case "${PRODUCT}" in
	"MCS") PRODUCT="AMSS"	    ;;
	"SLO") PRODUCT="SLROMS"	;;
	"SLA") PRODUCT="SLRAMS"	;;
esac

if [ "${ENVIRONMENT}" == "uat" ] && [ "${PRODUCT}" == "uat" ]; then
    Site
    exit 0
fi

if [ $# -lt 4 ]; then
    Usage 1
fi

Connect
exit 0
