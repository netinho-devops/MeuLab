#!/usr/bin/ksh
#===============================================================
# Name : deployHotfix
# Programmer: Andre Oliveira
# Date : 2016/08/08
# Purpose : Used to deploy HFs / Mark as Deployed in non clustered environment
#
# Changes history:
#
# Date       | By           | Changes/New features
# -----------+--------------+-----------------------------------
# 2016/08/08 | Andreo       | Script Creation
# 2016/10/31 | Andreo       | Updated to also deploy bundles / list of HF from file
# 2016/11/16 | Pedro Pavan  | Detailed output on log file
# 2016/11/24 | Pedro Pavan  | Removed env confirmation
#===============================================================

# Setting the properties of the script. The below values need to be changed according to the HFtool DB information of the account.
{
export HOTFIX_AMC_HOST="$(hostname)"
export HOTFIX_AMC_HOTFIX_HOME="/vivnas/viv/vivtools/"
export HOTFIX_AMC_HOTFIX_CONFIG_DIR="${HOTFIX_AMC_HOTFIX_HOME}/Amc-${HOTFIX_AMC_HOST}/config"
export HOTFIX_AMC_HOTFIX_DB_CONFIG_FILE="${HOTFIX_AMC_HOTFIX_CONFIG_DIR}/AmcRunSqlPIConList.xml"
export HOTFIX_HOME="${HOTFIX_AMC_HOTFIX_HOME}/hotfix"
export HOTFIX_DIRECTORIES="${HOTFIX_UNIX_USER}/hotfix/HOTFIX"
export HOTFIX_LOG="${HOTFIX_AMC_HOTFIX_HOME}hotfix/tmp/hf_deploy_$(date +%Y%m%d%H%M%S)_$$.log"

find ${HOTFIX_AMC_HOTFIX_HOME}/hotfix/tmp/ -type f -name "hf_deploy_*.log" -mtime +7

export HOTFIX_DB_USER="$(grep User ${HOTFIX_AMC_HOTFIX_DB_CONFIG_FILE} | sort -u | cut -d '>' -f 2 | cut -d '<' -f 1)"
export HOTFIX_DB_PASSWORD="$(grep Pass ${HOTFIX_AMC_HOTFIX_DB_CONFIG_FILE} | sort -u | cut -d '>' -f 2 | cut -d '<' -f 1)"
export HOTFIX_DB_INSTANCE="$(grep Url ${HOTFIX_AMC_HOTFIX_DB_CONFIG_FILE} | head -1 | cut -d '<' -f 2 | cut -d ':' -f 6)"
}

# Setting other variables and definitions used by the script
{
export HOTFIX_BUNDLE_NAME=""
export HOTFIX_FILELIST_NAME=""
export HOTFIX_NUMBER=""
export ERROR_MESSAGE=""

export HOTFIX_API_SCRIPT="${HOTFIX_HOME}/HotfixRunApi.ksh"
export HOTFIX_API_AVAILABLE_OPTIONS[0]="API_AUTO_DEPLOY"
export VIRTUAL_MACHINE_NAME="wrk"
export SCRIPTS_DIRECTORIES="${HOTFIX_UNIX_USER}/scripts"
export TEMP_FILE_1="/tmp/deployHotfix_TEMP_FILE_1_$$.txt"
export TEMP_FILE_2="/tmp/deployHotfix_TEMP_FILE_2_$$.txt"
export TEMP_FILE_HOTFIX_PRODUCTS="/tmp/deployHotfix_TEMP_FILE_HOTFIX_PRODUCTS_$$.txt"
export TEMP_FILE_HOTFIX_LIST="/tmp/deployHotfix_TEMP_FILE_HOTFIX_LIST_$$.txt"
export TEMP_FILE_ENV_LIST="/tmp/deployHotfix_TEMP_FILE_ENV_LIST_$$.txt"

export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export YELLOW=$(tput setaf 3)
export BLUE=$(tput setaf 4)
export WHITE=$(tput setaf 7)
export BRIGHT=$(tput bold)
export NORMAL=$(tput sgr0)
}

# Checking if the script is being used correctly
usage(){
    printf "${RED}${BRIGHT}%s${NORMAL}\n" "Incorrect Usage !" 
    printf "${GREEN}${BRIGHT}%s${NORMAL}\n" "Correct Usage:"
    printf "\t%s\n" "$0 -e|ve <ENVIRONMENT NUMBER> -d <HOTFIX NUMBER>  (To deploy single HF)"
    printf "\t%s\n" "$0 -e|ve <ENVIRONMENT NUMBER> -md <HOTFIX NUMBER> (To mark HF as deployed)"
    printf "\t%s\n" "$0 -e|ve <ENVIRONMENT NUMBER> -b                  (To select and deploy a bundle)"
    printf "\t%s\n" "$0 -e|ve <ENVIRONMENT NUMBER> -b <BUNDLE_NAME>    (To deploy bundle passed as parameter, to deploy more than 1 bundle: bundle1,bundle2,bundl3)"
    printf "\t%s\n" "$0 -e|ve <ENVIRONMENT NUMBER> -f <FILE_NAME>      (To deploy HFs from a file separated each hf in a different line."
    printf "\n"
	printf "\t%s\n" "By default confirmation/information will be displayed before deployment, use option below to hide: "
	printf "\t%s\n" " -c : Hide confirmation"
	printf "\t%s\n" " -i : Hide information"
	printf "\t%s\n" " -w : Do not stop in case of failure"
    printf "\n"
}

# Functions that will be used on the script

## This function is used to validate HF: is rejected? has manual steps? is auto deploy?
validateHF() {
	hotfix_number=$1

	result=$(sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
	SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
    SELECT
	   DECODE((SELECT COUNT(UNIQUE_ID) FROM HOTFIX_EVT WHERE UNIQUE_ID = M.UNIQUE_ID AND EVENT_NAME = 'REJECTED'), 0,'NO', 1,'YES', 'YES') AS REJECTED,
       DECODE((SELECT COUNT(UNIQUE_ID) FROM HOTFIX_MNG WHERE UNIQUE_ID = M.UNIQUE_ID AND UNIQUE_ID NOT IN (SELECT UNIQUE_ID FROM HOTFIX_AUTO_DEPLOY)), 0, 'YES', 1, 'NO', 'NO') AS AUTO_DEPLOY,
       DECODE((SELECT COUNT(UNIQUE_ID) FROM HOTFIX_MNG WHERE UNIQUE_ID = M.UNIQUE_ID AND UNIQUE_ID IN (
               SELECT UNIQUE_ID FROM HOTFIX_AP_RELATIONS WHERE UNIQUE_ID = M.UNIQUE_ID AND PARAM_ID = 1 AND PARAM_VALUE = 'YES')), 0, 'NO', 1, 'YES', 'YES') AS MANUAL_STEP,
	   M.PRODUCT AS PRODUCT
	FROM HOTFIX_MNG M WHERE M.UNIQUE_ID = ${hotfix_number};
SQL)

	REJECTED=$(echo ${result} | awk '{ print $1 }')
	AD=$(echo ${result} | awk '{ print $2 }')
	MN_STEP=$(echo ${result} | awk '{ print $3 }')
	PRODUCT=$(echo ${result} | awk '{ print $4 }')

	if [ "${REJECTED}" == "YES" ]; then
		echo 10
		return 0
	fi 

	if [ "${AD}" == "NO" ]; then
		echo 20
		return 0
	fi

	if [ "${MN_STEP}" == "YES" ]; then
		echo 30
		return 0
	fi
	
	if [ "${PRODUCT}" == "AUA" ]; then
		echo 40
		return 0
	fi

	echo 0
	return 0
}

## This function is used to deploy the AD hotfix in a non clustered environment.
deployHF(){
    HOTFIX_API_USED_OPTION=${HOTFIX_API_AVAILABLE_OPTIONS[0]}
    HOTFIX_NUMBER=$1
    ENVIRONMENT=$2

	echo -e "\n\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" >> ${HOTFIX_LOG}
	echo -e "@@@ ${HOTFIX_NUMBER} on ${ENVIRONMENT}" >> ${HOTFIX_LOG}
	echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" >> ${HOTFIX_LOG}

    ${HOTFIX_API_SCRIPT} ${HOTFIX_API_USED_OPTION} ${HOTFIX_NUMBER} ${ENVIRONMENT}
}

## This function is used to mark an HF as deployed in a non clustered environment.
markHFAsDeployed(){
    hotfix_number=$1
    environment=$2
    
    printf "${NORMAL}%-23s${GREEN}%s${NORMAL}\n" "Marking the HF: " "${hotfix_number}"
    printf "${NORMAL}%-23s${GREEN}%s${NORMAL}\n" "As Deployed in: " "${environment}"
    
    sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
    SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
    Insert into HOTFIX_EVT
    (UNIQUE_ID, EVENT_NAME, FILE_NAME, ENVIRONMENT, CREATION_DATE, DEST_PATH, LAST_MODIFIED_BY,  HF_COMMENT, DEPLOY_TYPE)
    Values
   ($hotfix_number, 'DEPLOYED', 'N/A', '$environment', sysdate, 'N/A', 'ApiAdmin', 'Deployed manually', 'MANUAL');
    commit;
SQL
}

## This function gets the Physical user_name@host for the environment, based on the product and environment numbers passed as parameters.
getEnvUserHost(){
    product=$1
    environment_number=$2
    sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
    SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
    select product, environment 
    from HOTFIX_CTL
    where product = '$product'
    and environment like '______${environment_number}@%' and environment not like '%${VIRTUAL_MACHINE_NAME}%';
SQL
}

## This function gets the Virtual user_name@host for the environment, based on the product and environment numbers passed as parameters.
getVirtualEnvUserHost(){
    product=$1
    environment_number=$2
    sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
    SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
    select product || ' ' ||  environment 
    from HOTFIX_CTL
    where product = '$product'
    and environment like '%${VIRTUAL_MACHINE_NAME}%${environment_number}';
SQL
}

## This function is used to get the last X bundle names from the HFtool
getAllBundlesNames(){
    number_of_bundles_to_be_fetched=20
    sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
    SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
    select bundle_name 
    from (select bundle_name, sys_creation_date
    from HOTFIX_BUNDLES
    where 1=1
    and order_num=1
    order by 2 desc)
    where rownum < '${number_of_bundles_to_be_fetched}';
SQL
}

## This functions gets all the HFs product number and deploy order from a bundle.
getBundleHFs(){
    hotfix_bundle_name=$1
    sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
    SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
    select hm.product, hb.unique_id, hb.order_num
    from HOTFIX_BUNDLES hb, HOTFIX_MNG hm
    where 1=1
    and hb.bundle_name='$hotfix_bundle_name'
    and hb.unique_id=hm.unique_id
    order by 3 asc;
SQL
}

# This functions gets the HF product using the HF number as parameter.
getHFDetails(){
    hotfix_number=$1
    sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
    SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
    select hm.product, hm.unique_id
    from HOTFIX_MNG hm
    where 1=1
    and hm.unique_id='$hotfix_number';
SQL
}

## Receiveis input file, output file, message string in that order, then prints the contents of the input file in a numbered option list, receives input from user placing the selected option in the output file, and prints the message received as parameter.
listValues(){
    clear
    input_file=$1
    ouput_file=$2
    string=$3
    num=1
    while read line_from_file
    do
    printf "${NORMAL}%-6s${NORMAL}%s${NORMAL}\n" '('${num}') ' "${line_from_file}"
    num=$((num+1))
    done < ${input_file}
    printf "${string}"
    read "value"  </dev/tty
    printf "$(sed -n "${value}p" ${input_file})\n" > ${ouput_file}
}

## This functions asks for a random number before the execution.
randomNumberValidator(){
    printf "${BRIGHT}%s${NORMAL}\n\n" "Enter the below random number to confirm that you are not drunk."
    #used_random_number=$RANDOM
	used_random_number=$(echo $RANDOM % 10000 + 1 | bc)
    printf "${BRIGHT}${GREEN}%s${NORMAL}\n\n" "${used_random_number}"
    printf "${BRIGHT}%s${NORMAL}" "The number is: "
    read input
    if [[ "${input}" -ne "${used_random_number}" ]]
    then
        printf "${BRIGHT}${RED}%s${NORMAL}\n" "Entered number does not match!"
        return 1
    else
        printf "${BRIGHT}${GREEN}%s${NORMAL}\n" "Entered number matches!"
        return 0
    fi
}

# This function removes blank lines from a file
removeBlankLine(){
    perl -pi -e "s/^\n//" ${1}
}

# This functions remove the temporary files that were created
cleanTempFiles(){
    rm -f ${TEMP_FILE_1}
    rm -f ${TEMP_FILE_2}
    rm -f ${TEMP_FILE_HOTFIX_LIST}
    rm -f ${TEMP_FILE_ENV_LIST}
    rm -f ${TEMP_FILE_HOTFIX_PRODUCTS}
}

######################################################
##           Main execution of the script           ##
######################################################

if [[ $# -lt 3 ]]
then
    usage
    exit 1 
fi

export ENVIRONMENT_TYPE=$1
export ENVIRONMENT_NUMBER=$2
export DEPLOY_MODE=$3
export DEPLOY_ARGUMENT=$4

case $DEPLOY_MODE in
  "-md")
        HOTFIX_NUMBER=${DEPLOY_ARGUMENT}
        getHFDetails ${HOTFIX_NUMBER} > ${TEMP_FILE_HOTFIX_LIST}
        ERROR_MESSAGE="The HOTFIX ${HOTFIX_NUMBER} does not exist or the HF was not synched yet!"
        ;;
  "-d")
        HOTFIX_NUMBER=${DEPLOY_ARGUMENT}
        getHFDetails ${HOTFIX_NUMBER} > ${TEMP_FILE_HOTFIX_LIST}
        ERROR_MESSAGE="The HOTFIX ${HOTFIX_NUMBER} does not exist or the HF was not synched yet!"
        ;;
  "-b")
        ## Option used to get the bundle name and hotfixes.
        export HOTFIX_BUNDLE_NAME=${DEPLOY_ARGUMENT}
        if [[ X${HOTFIX_BUNDLE_NAME} == X ]]
        then
            getAllBundlesNames > ${TEMP_FILE_1}
            removeBlankLine ${TEMP_FILE_1}
            listValues ${TEMP_FILE_1} ${TEMP_FILE_2} "--- Type the number which represents the desired BUNDLE: "
            HOTFIX_BUNDLE_NAME="$(cat ${TEMP_FILE_2})"
        fi
        
        if [[ ${HOTFIX_BUNDLE_NAME} == *","* ]]; then
			for bundle in $(echo ${HOTFIX_BUNDLE_NAME} | tr ',' '\n'); do
				getBundleHFs ${bundle} >> ${TEMP_FILE_HOTFIX_LIST}
			done
		else
			getBundleHFs ${HOTFIX_BUNDLE_NAME} > ${TEMP_FILE_HOTFIX_LIST}
		fi

        ERROR_MESSAGE="The Bundle ${HOTFIX_BUNDLE_NAME} does not exist in the DB or the HFs were not synched yet!"
        ;;
  "-f")
        ## Option used to get the hotfixes passed from a file as parameter.
        HOTFIX_FILELIST_NAME=${DEPLOY_ARGUMENT}
        if [[ ! -f ${HOTFIX_FILELIST_NAME} ]]
        then
            ERROR_MESSAGE "${RED}${BRIGHT}%s\n${NORMAL}" "File does not exist."
            cleanTempFiles
            exit
        fi
        printf "${RED}${BRIGHT}%s\n${NORMAL}" "${ERROR_MESSAGE}"
        
        while read hf_to_deploy
        do
            getHFDetails ${hf_to_deploy} >> ${TEMP_FILE_HOTFIX_LIST}
        done < ${HOTFIX_FILELIST_NAME}
        ;;
  "*")
        usage
        exit 1
        ;;
esac

# Aditional parameters
shift 4

DISPLAY_CONFIRMATION="Y"
DISPLAY_INFORMATION="Y"
FAILED_CONFIRMATION="N"

for param in $*; do
	case ${param} in
		"-c") DISPLAY_CONFIRMATION="N"	;;
		"-i") DISPLAY_INFORMATION="N"	;;
		"-w") FAILED_CONFIRMATION="Y"	;;
	esac
done

### Checking if the HF list retrieved in the previous steps is empty.
removeBlankLine ${TEMP_FILE_HOTFIX_LIST}
if [[ ! -s ${TEMP_FILE_HOTFIX_LIST} ]]
then
    printf "${RED}${BRIGHT}%s\n${NORMAL}" "${ERROR_MESSAGE}"
    cleanTempFiles
    exit 1
fi

### Getting the full username@host which will be used to deploy the HF in later steps and placing the details in the file TEMP_FILE_ENV_LIST
cat ${TEMP_FILE_HOTFIX_LIST} | awk '{print $1}' | sort -u > ${TEMP_FILE_HOTFIX_PRODUCTS}
while read hfs_products
do
    if [[ ${ENVIRONMENT_TYPE} == '-e' ]]
    then
        getEnvUserHost ${hfs_products} ${ENVIRONMENT_NUMBER} > ${TEMP_FILE_1}
    else
        getVirtualEnvUserHost ${hfs_products} ${ENVIRONMENT_NUMBER} > ${TEMP_FILE_1}
    fi
    removeBlankLine ${TEMP_FILE_1}
    #listValues ${TEMP_FILE_1} ${TEMP_FILE_2} "--- Type the number to confirm the ENVIRONMENT for ${hfs_products}: "
    #cat ${TEMP_FILE_2} >> ${TEMP_FILE_ENV_LIST}
	cat ${TEMP_FILE_1} >> ${TEMP_FILE_ENV_LIST}
done < ${TEMP_FILE_HOTFIX_PRODUCTS}
printf "\n"

### Checking if the ENV list retrieved in the previous steps is empty.
if [[ ! -s ${TEMP_FILE_ENV_LIST} ]]
then
    printf "${RED}${BRIGHT}%s\n${NORMAL}" "Environment list is empty!"
    cleanTempFiles
    exit 1
fi

### Showing the list of HFs which will be deployed
if [ "${DISPLAY_INFORMATION}" == "Y" ]; then
	printf "${BRIGHT}%s\n\n" "The HFs will be deployed in the below order."
	printf "${BRIGHT}%-10s\t%-15s\t%-5s${NORMAL}\n" "PRODUCT" "HOTFIX NUMBER" "DEPLOY ORDER"
	
	while read hf_list_to_deploy
	do
	    printf "${BRIGHT}%-10s\t%-15s\t%-5s${NORMAL}\n" "  $(echo ${hf_list_to_deploy}| awk '{print $1}')" "  $(echo ${hf_list_to_deploy}| awk '{print $2}')" "      $(echo ${hf_list_to_deploy}| awk '{print $3}')"
	done < ${TEMP_FILE_HOTFIX_LIST}
	sleep 1
fi

## Checking for confirmation before the HF deploy.
if [ "${DISPLAY_CONFIRMATION}" == "Y" ]; then
	printf "\n"
	printf "${BRIGHT}%s\n${NORMAL}" "Please CONFIRM that the deploy must be done in the below ENVIRONMENT"
	printf "------------------------------------\n"
	while read hotfix_enviroment
	do
	    printf "${BRIGHT}%-10s\t%-15s${NORMAL}\n" "  $(echo ${hotfix_enviroment}| awk '{print $1}')" "  $(echo ${hotfix_enviroment}| awk '{print $2}')"
	done < ${TEMP_FILE_ENV_LIST}
	printf "------------------------------------\n"

	randomNumberValidator
fi

if [[ "$?" -ne "0" ]]
then
    printf "${RED}${BRIGHT}%s\n${NORMAL}" "Wrong confirmation value typed."
    cleanTempFiles
    exit 1
fi

sleep 1

if [[ "${DEPLOY_MODE}" == "-md" ]]
then
    ### Running the commands which will deploy the HFs.
    while read hf_to_deploy
    do
        HF_NUMBER=$(printf "${hf_to_deploy}" | awk '{print $2}')
        HF_PRODUCT=$(printf "${hf_to_deploy}" | awk '{print $1}')
        ENVIRONMENT=$(grep -P "^${HF_PRODUCT}" ${TEMP_FILE_ENV_LIST} | awk '{print $2}')
        markHFAsDeployed ${HF_NUMBER} ${ENVIRONMENT}
    done < ${TEMP_FILE_HOTFIX_LIST}
else
    ### Running the commands which will deploy the HFs.
	HF_COUNT=0
	export MANUAL_HF_FOUND="N"
	printf "%s\n\n" "LOG: ${HOTFIX_LOG}"

    while read hf_to_deploy
    do
        HF_NUMBER=$(printf "${hf_to_deploy}" | awk '{print $2}')
        HF_PRODUCT=$(printf "${hf_to_deploy}" | awk '{print $1}')
        ENVIRONMENT=$(grep -P "^${HF_PRODUCT}" ${TEMP_FILE_ENV_LIST} | awk '{print $2}')
		HF_COUNT=$(expr ${HF_COUNT} + 1)
		
		echo -n "[${HF_COUNT}] HF#${HF_NUMBER}: "
		HF_VALIDATION=$(validateHF "${HF_NUMBER}")
		case ${HF_VALIDATION} in
			10)	echo "${RED}${BRIGHT}REJECTED${NORMAL}"				;;
			20) echo "${YELLOW}${BRIGHT}MANUAL${NORMAL}"	
				export MANUAL_HF_FOUND="Y"							;;
			30) echo "${BLUE}${BRIGHT}ADDITIONAL STEPS${NORMAL}"	;;
			40) echo "${YELLOW}${BRIGHT}IGNORED (OSS)${NORMAL}"		;;
			 0)
				deployHF ${HF_NUMBER} ${ENVIRONMENT} >> ${HOTFIX_LOG} 2>&1
		        if [[ $? -ne 0 ]]; then
        		    echo -e "${RED}${BRIGHT}FAILED${NORMAL}\n"

					if [ "${FAILED_CONFIRMATION}" == "N" ]; then
		            	cleanTempFiles
        		    	exit 1
					fi
		        else
					echo "${GREEN}${BRIGHT}DEPLOYED${NORMAL}"
				fi  
			;;
		esac  
    done < ${TEMP_FILE_HOTFIX_LIST}
fi
cleanTempFiles
