#!/bin/ksh
#===============================================================
# NAME      :  HotfixMarkEnvAsRefreshed.ksh
# Programmer:  Pedro Pavan
# Date      :  26-Jan-15
# Purpose   :  Mark environment as refreshed
#
# Changes history:
#
#  Date     |    By       | Changes/New features
# ----------+-------------+-------------------------------------
# 01-26-15    Pedro Pavan   Initial version
#===============================================================

######################################
# Usage
######################################
Usage() {
    EXIT_CODE=$1

    echo ""
    echo "Usage: $(basename $0) -e <env_number> -p <product_name> -d <date_time> [-h]"
    echo ""
    echo "  -d   Data/Time													"
	echo "        Format: DD/MM/YYYY HH:MM:SS					"
	echo "        NOW (current date time)								"
    echo ""
    echo "  -p   Product	 (ABP, CRM, OMS, ALL)						"
    echo ""
    echo "  -e   Environment number									"
    echo ""
    echo "  -h   Display help                                         		"
    echo ""

    exit ${EXIT_CODE}
}

######################################
# HF Tool DB
######################################
Get_Genesis_DB() {
	echo "$AMC_REPOSITORY_DATABASE_USERNAME/$AMC_REPOSITORY_DATABASE_PASSWORD@$AMC_REPOSITORY_DATABASE_INSTANCE"
}

######################################
# Get Environment Connection
######################################
Get_Env_Conn() {
	ACCOUNT=$1
	HF_DB_CONN=$(Get_Genesis_DB)
	
	ENV=$(print "
        WHENEVER SQLERROR EXIT 5
        SET FEEDBACK OFF
        SET HEADING OFF
        SET PAGES 0
        SET LINE 500

		SELECT environment FROM hotfix_environments	WHERE environment LIKE '${ACCOUNT}@%';
	" | sqlplus -S ${HF_DB_CONN})
	
	if [ "$(echo ${ENV} | wc -l)" != "1" ]; then
		echo "Too many rows returned, please check. Exiting!"
		exit 1
	fi
	
	echo ${ENV}
}

######################################
# Set date/time
######################################
Set_Date_Time() {
	HF_DB_CONN=$(Get_Genesis_DB)
	ACCOUNT="$(Get_Env_Conn $1)"
	DATE_TIME="$2 $3"
	if [ "${DATE_TIME}" == "now " ] || [ "${DATE_TIME}" == "NOW " ] || [ "${DATE_TIME}" == "sysdate " ]; then
		DATE_TIME="sysdate"
	else
		DATE_TIME="'TO_DATE('${DATE_TIME}', 'DD/MM/YYYY HH24:MI:SS')"
	fi
	
	#UPDATE HOTFIX_ENVIRONMENTS SET REFRESH_DATE = TO_DATE('15/07/2014 16:00:00', 'DD/MM/YYYY HH24:MI:SS') WHERE ENVIRONMENT = 'tifabp2@snelnx195';
	print "
		SET FEEDBACK OFF
		UPDATE HOTFIX_ENVIRONMENTS SET REFRESH_DATE = ${DATE_TIME} WHERE ENVIRONMENT = '${ACCOUNT}';
		COMMIT;
	"  | sqlplus -S ${HF_DB_CONN}
	
	if [ $? -eq 0 ]; then
		CURRENT_DATE=$(print "
        	WHENEVER SQLERROR EXIT 5
	        SET FEEDBACK OFF
        	SET HEADING OFF
	        SET PAGES 0
        	SET LINE 500		
			
			SELECT TO_CHAR(refresh_date, 'MM/DD/YYYY HH24:MI:SS') FROM hotfix_environments WHERE environment = '${ACCOUNT}';
		" | sqlplus -S ${HF_DB_CONN})
	
		echo -e "\n==> Account '${ACCOUNT}' was marked as refreshed successfully"
		echo "==> From: ${CURRENT_DATE} to: ${DATE_TIME}"
	else
		echo -e "\n==> Failed to mark account as refreshed."
	fi
}

######################################
# Mask as refreshed
######################################
Mark_As_Refreshed() {
	PRODUCT=$(echo $1 | tr '[A-Z]' '[a-z]')	
	[ "${PRODUCT}" == "enb" ] && PRODUCT="abp"
	ENVIRONMENT=$2
	DATE_TIME="$3 $4"
	
	CONN="tif${PRODUCT}${ENVIRONMENT}"
	
	if [ "${PRODUCT}" == "all" ]; then
		for p in abp crm oms; do
			CONN="tif${p}${ENVIRONMENT}"
			Set_Date_Time ${CONN} ${DATE_TIME}	
		done
	else
		CONN="tif${PRODUCT}${ENVIRONMENT}"
		Set_Date_Time ${CONN} ${DATE_TIME}
	fi
}

######################################
# Main
######################################
cd ~/utility_scripts/hotfix/refreshed

while getopts ":e:p:d:h" opt
do 
    case "${opt}" in
        e) ENV_NUMBER=${OPTARG}			;;
        p) ENV_PRODUCT=${OPTARG}		;;
		d) ENV_DATETIME=${OPTARG}		;;
        h) Usage 0              					;;
        *) Usage 1              					;;
    esac
done

if [ $# -lt 6 ]; then
    Usage 1
fi

Mark_As_Refreshed ${ENV_PRODUCT} ${ENV_NUMBER} "${ENV_DATETIME}"

exit 0