#!/bin/ksh
#===============================================================
# NAME      :  HotfixDeployList.ksh
# Programmer:  Pedro Pavan
# Date      :  10-Oct-14
# Purpose   :  Deploy HF list (only auto deploy)
#
# Changes history:
#
#  Date     | 		By         | Changes/New features
# ----------+------------------+-------------------------------------
# 10-03-14    Pedro Pavan        Initial version
# 04-04-15    Pedro Pavan        Deploy NET Bundle
# 14-04-15    Pedro Pavan        Default answer
# 15-04-15    Pedro Pavan        E-mail status
# 16-04-15    Ricardo Gesuatto   Move FILE to FILE.done on success
# 17-06-15    Ricardo Gesuatto   Wait on manual hotfix
#=====================================================================
MARKET="net"

######################################
# Usage
######################################
Usage() {
    EXIT_CODE=$1

    echo ""
    echo "Usage: $(basename $0) -e <environment> -i <hf_id>			"
    echo "       $(basename $0) -e <environment> -f <file_list>		"
    echo "       $(basename $0) -e <environment> -b <bundle_name>	"
    echo ""
    echo "  -i   HF ID												"
    echo ""    
	echo "  -f   HF file											"
    echo ""
	echo "  -b   HF bundle											"	
    echo ""
    echo "  -e   Environment number 								"
    echo ""
    echo "  -a   Default answer, if needed (y/n)					"
    echo ""
    echo "  -w   Wait for confirmation on manual hotfix             "
    echo ""
    echo "  -m   Send e-mail status 								"
    echo ""
    echo "  -p   Specific product (ABP, CRM, OMS, AMS, OPX)			"
    echo ""
    echo "  -h   Display help                      	              	"
    echo ""

    exit ${EXIT_CODE}
}

######################################
# HF Tool DB
######################################
Get_Genesis_DB() {
	echo "${AMC_REPOSITORY_DATABASE_USERNAME}/${AMC_REPOSITORY_DATABASE_PASSWORD}@${AMC_REPOSITORY_DATABASE_INSTANCE}"
}

######################################
# Write date and time
######################################
DateTime() {
	echo $(/bin/date '+%Y-%m-%d %H:%M:%S')
}

######################################
# Display verbose message
######################################
Message() {
	MSG=$2
	TYPE=$1
	
	COLOR_RED="\033[31m"
	COLOR_GREEN="\033[32m"
	COLOR_YELLOW="\033[33m"
	COLOR_BLUE="\033[34m"
	COLOR_END="\033[0m"
	
	case "${TYPE}" in
		"-deployed")	echo -e " ${COLOR_GREEN}DEPLOYED${COLOR_END}\t"${MSG} ; echo -e " DEPLOYED\t${MSG}" >> ${MAIL_FILE}	;;
		  "-failed")	echo -e " ${COLOR_RED}FAILED${COLOR_END}\t"${MSG}	  ; echo -e " FAILED\t${MSG}" >> ${MAIL_FILE}	;;
		"-approved")	echo -e " ${COLOR_BLUE}APPROVED${COLOR_END}\t"${MSG}  ; echo -e " APPROVED\t${MSG}" >> ${MAIL_FILE}	;;
		 "-skipped")	echo -e " ${COLOR_YELLOW}SKIPPED${COLOR_END}\t"${MSG} ; echo -e " SKIPPED\t${MSG}" >> ${MAIL_FILE}	;;
		   "-alert")	echo -e " ${COLOR_YELLOW}ALERT${COLOR_END}\t"${MSG}	  ; echo -e " ALERT\t${MSG}" >> ${MAIL_FILE}	;;
	esac
}

######################################
# Display verbose message
######################################
Border() {
	MSG=$1

	COLOR_MAGENTA="\033[35m"
	COLOR_END="\033[0m"
	echo -e "\n${COLOR_MAGENTA}********** ENV#${MSG} **********${COLOR_END}"
}

######################################
# Send email
######################################
Send_Mail() {

    if [ "${EMAIL_ENABLE}" == "Y" ]; then
		echo -e "\n\n" >> ${MAIL_FILE}
		cat ${LOG_FILE} >> ${MAIL_FILE}		
        cat ${MAIL_FILE} | mailx -s "HF DEPLOYMENT: ${PARAM}" ${EMAIL_ADDRESS}
    fi
}

######################################
# Exit script
######################################
Finish() {
	EXIT_CODE=$1

	case ${EXIT_CODE} in
		 0)	STATUS="Ended successfully"	;;
		11) STATUS="Deployment failed"  ;;
		12) STATUS="Deployment failed"  ;;
		13) STATUS="Deployment failed"  ;;
		14) STATUS="Cancelled by user"  ;;
		15) STATUS="Cancelled by user"  ;;
		16) STATUS="Aborted by user"  	;;
		 *) STATUS="Execution failed"   ;;
	esac
	
	echo -e "\n" | tee -a ${LOG_FILE}
	echo "==============================================" | tee -a ${LOG_FILE}
	echo " <<< ${STATUS} >>>							" | tee -a ${LOG_FILE}
	echo " Finish time $(DateTime)						" | tee -a ${LOG_FILE}
	echo "==============================================" | tee -a ${LOG_FILE}
	
	Send_Mail

	[ -f ${FILE} ] && [ ${EXIT_CODE} -eq 0 ] &&  touch -c ${FILE} && mv ${FILE} ${FILE}.DONE
    [ -f ${MAIL_FILE} ] && rm -f ${MAIL_FILE}

	exit ${EXIT_CODE}
}

######################################
# Validate HF list
######################################
Validade() {
	HF_ID=$1
	
	HF_INFO=$(print "
        WHENEVER SQLERROR EXIT 5
        SET FEEDBACK OFF
        SET HEADING OFF
        SET PAGES 0
        SET LINE 500

		SELECT
			DECODE((SELECT COUNT(UNIQUE_ID) FROM HOTFIX_EVT WHERE UNIQUE_ID = M.UNIQUE_ID AND EVENT_NAME = 'APPROVED'),0,'NO',1,'YES','YES') AS APPROVED,
		   	DECODE((SELECT COUNT(UNIQUE_ID) FROM HOTFIX_EVT WHERE UNIQUE_ID = M.UNIQUE_ID AND EVENT_NAME = 'REJECTED'),0,'NO',1,'YES','YES') AS REJECTED,
   			DECODE((SELECT COUNT(UNIQUE_ID) FROM HOTFIX_MNG WHERE UNIQUE_ID = M.UNIQUE_ID AND UNIQUE_ID IN (
					SELECT UNIQUE_ID FROM HOTFIX_AP_RELATIONS WHERE UNIQUE_ID = M.UNIQUE_ID AND PARAM_ID = 1 AND PARAM_VALUE = 'YES')),0, 'NO',1, 'YES','YES') AS MANUAL_STEP,
   			DECODE((SELECT COUNT(UNIQUE_ID) FROM HOTFIX_MNG WHERE UNIQUE_ID = M.UNIQUE_ID AND UNIQUE_ID NOT IN (SELECT UNIQUE_ID FROM HOTFIX_AUTO_DEPLOY)),0, 'YES',1, 'NO','NO') AS AUTO_DEPLOY,
			M.PRODUCT AS PRODUCT
 		FROM HOTFIX_MNG M
		WHERE M.UNIQUE_ID = ${HF_ID}
		ORDER BY M.UNIQUE_ID ASC;		
	" | sqlplus -S ${HF_DB_CON})
	
	APPROVED=$(echo ${HF_INFO} | awk '{ print $1 }')
	REJECTED=$(echo ${HF_INFO} | awk '{ print $2 }')
	MANUAL_STEP=$(echo ${HF_INFO} | awk '{ print $3 }')
	AUTO_DEPLOY=$(echo ${HF_INFO} | awk '{ print $4 }')
	HF_PRODUCT=$(echo ${HF_INFO} | awk '{ print $5 }')
	
	# Level 0 - product
	if [ "${PRODUCT_ENABLE}" == "Y" ]; then
		PRODUCT_VALUE=$(echo ${PRODUCT_VALUE} | tr '[a-z]' '[A-Z]')
		if [ "${PRODUCT_VALUE}" != "${HF_PRODUCT}" ]; then		
			echo 1
			return
		fi
	fi
	
	# Level 1 - rejected
	if [ "${REJECTED}" == "YES" ]; then
		echo 10
		return
	fi

	# Level 2 - auto deploy
	if [ "${AUTO_DEPLOY}" == "NO" ]; then
		echo 20
		return
	fi
	
	# Level 3 - manual step
	if [ "${MANUAL_STEP}" == "YES" ]; then
		echo 30
		return
	fi
	
	# Level 4 - approved
	if [ "${APPROVED}" == "NO" ]; then
		echo 40
		return
	fi
	
	echo 0
}

######################################
# Deploy
######################################
Deploy() {
	HF_ID=$1
	HF_ENV=$2
	
	HF_PRODUCT=$(print "
        WHENEVER SQLERROR EXIT 5
        SET FEEDBACK OFF
        SET HEADING OFF
        SET PAGES 0
        SET LINE 500
		
		SELECT LOWER(product) FROM hotfix_mng WHERE unique_id = ${HF_ID};
		" | sqlplus -S ${HF_DB_CON})
		
	case "${HF_PRODUCT}" in
		"amss")			HF_PRODUCT="ams"	;;
		"epc-abp")		HF_PRODUCT="abp"	;;
		"epc-oms")		HF_PRODUCT="oms"	;;
	esac

	HF_ACCOUNT=$(print "
        WHENEVER SQLERROR EXIT 5
        SET FEEDBACK OFF
        SET HEADING OFF
        SET PAGES 0
        SET LINE 500
		
		SELECT environment FROM hotfix_environments	WHERE environment LIKE '${MARKET}${HF_PRODUCT}${HF_ENV}@%';
		" | sqlplus -S ${HF_DB_CON})
	
	echo -e "\n\n_______________________________ HF#${HF_ID} on ENV#${HF_ENV} (${HF_ACCOUNT}) [$(DateTime)] _______________________________" >> ${LOG_FILE}

	# REAL MODE
	STATUS=$(~/hotfix/HotfixRunApi.ksh API_AUTO_DEPLOY ${HF_ID} ${HF_ACCOUNT} >> ${LOG_FILE} 2>&1 ; echo $?)
	
	# DEBUG MODE
	#echo -e "~/hotfix/HotfixRunApi.ksh API_AUTO_DEPLOY ${HF_ID} ${HF_ACCOUNT}" >> ${LOG_FILE}
	#STATUS=0 ; sleep 2
	
	case ${STATUS} in
		0) 
			Message -deployed	
		;;              
		                
		1)              
			Message -failed
			Finish 11
		;;              
		                
		2)              
			Message -failed
			Finish 12  
		;;              
		                
		*) Message -skipped
		   Finish 13
		;;
	esac
}

######################################
# Deploy Single
######################################
Deploy_Single() {
	HF_ID=$1
	HF_ENV=$2
	
	echo -ne "[+] HF#${HF_ID}:" | tee -a ${MAIL_FILE}

	VALIDATION=$(Validade ${HF_ID})

	case ${VALIDATION} in
         0)	Deploy ${HF_ID} ${HF_ENV}							;;
         1)	Message -skipped "(only ${PRODUCT_VALUE})"          ;;
		10)	Message -skipped "(was rejected)"					;;
		20)	if [ "${WAIT_MANUAL}" == "Y" ]; then
                choice=${ANSWER_VALUE}
                Message -alert   "- It must be deployed manually, Continue (y/n)? \c" ; read choice
                case "$choice" in
                    y|Y)                                        ;;
                    n|N) Finish 14                              ;;
                      *) Finish 15                              ;;
                esac
            else
                Message -skipped   "(must be deployed manually)"
            fi
            ;;
		30)	Message -skipped "(contains manual step)"			;;
		40)	if [ "${ANSWER_ENABLE}" == "Y" ]; then
				choice=${ANSWER_VALUE}				
                case "$choice" in
                    y|Y) Message -skipped "(was not approved)"	;;
                    n|N) Message -skipped ; Finish 14			;;
                      *) Finish 15								;;
                esac


			else
				Message -alert   "- It's not approved, Continue (y/n)? \c" ; read choice
				case "$choice" in 
                    y|Y) 										;;
                    n|N) Finish 14								;;
					  *) Finish 15								;;
				esac
			fi
			;;
	esac
}

######################################
# Deploy List
######################################
Deploy_List() {
	FILE=$1
	HF_ENV=$2
	
	for hf in $(cat ${FILE} | egrep -v "^#" | sort -n | uniq); do
		Deploy_Single ${hf} ${HF_ENV}
	done
}

######################################
# Deploy Bundle
######################################
Deploy_Bundle() {
	HF_BUNDLE=$1
	HF_ENV=$2
	
	FILE="bundle_tmp.txt"
	
	print "
        WHENEVER SQLERROR EXIT 5
        SET FEEDBACK OFF
        SET HEADING OFF
        SET PAGES 0
        SET LINE 500
	
		SELECT unique_id FROM hotfix_bundles WHERE bundle_name = '${HF_BUNDLE}' ORDER BY order_num ASC;
		" | sqlplus -S ${HF_DB_CON} > ${FILE}
	
	if [ "$(wc -l ${FILE})" == "0" ]; then
		echo "Bundle '${HF_BUNDLE}' was not found!"
	fi

	Deploy_List ${FILE} ${HF_ENV}
}

######################################
# Main
######################################
ANSWER_ENABLE="N"
EMAIL_ENABLE="N"
PRODUCT_ENABLE="N"
RUN_MODE="X"
WAIT_MANUAL="N"

LOG_FILE="deployment.log"
MAIL_FILE="mail.log"

> ${LOG_FILE}
> ${MAIL_FILE}

trap 'Finish 16' SIGTERM SIGINT

while getopts ":i:b:f:e:a:m:p:h:w" opt
do 
    case "${opt}" in
        h)	Usage 0											;;
		i)	RUN_MODE="I" ; PARAM=${OPTARG}					;;
		b)	RUN_MODE="B" ; PARAM=${OPTARG}					;;
		f)	RUN_MODE="F" ; PARAM=${OPTARG}					;;
		a)	ANSWER_ENABLE="Y"  ; ANSWER_VALUE=${OPTARG}		;;
		m)	EMAIL_ENABLE="Y"   ; EMAIL_ADDRESS=${OPTARG}	;;
		p)	PRODUCT_ENABLE="Y" ; PRODUCT_VALUE=${OPTARG}	;;
        e)	ENVIRONMENT=${OPTARG}							;;
        w)  WAIT_MANUAL="Y"                                 ;;
        *)  Usage 1											;;
    esac 
done

if [ $# -lt 4 ]; then
    Usage 2
fi

if [ -z ${ENVIRONMENT} ]; then
	Usage 3
fi

if [ "${RUN_MODE}" == "X" ]; then
	Usage 4
fi

HF_DB_CON=$(Get_Genesis_DB)

clear
echo "==============================================" | tee -a ${LOG_FILE}
echo " Start time $(DateTime)						" | tee -a ${LOG_FILE}
echo " Log file: $(pwd)/deployment.log              " | tee -a ${LOG_FILE}
echo "==============================================" | tee -a ${LOG_FILE}
echo ""

for env in $(echo ${ENVIRONMENT} | tr ',' '\n' | egrep -v "^$"); do
	Border ${env}

	case "${RUN_MODE}" in
		"I")	Deploy_Single ${PARAM} ${env}	;;
		"B")	Deploy_Bundle ${PARAM} ${env}	;;
		"F")	Deploy_List ${PARAM} ${env}		;;
	esac

done

Finish 0
