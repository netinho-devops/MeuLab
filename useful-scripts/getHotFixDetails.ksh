#!/usr/bin/ksh
# Script used to connect into the HF Tool Database, and gather some informations from a HF.
#===============================================================
# Name : getHFDetails
# Programmer: Andre Oliveira / Gustavo Kuraim
# Date : 2014/09/15
# Purpose : Get some HF high level details from the HFtool
#
# Changes history:
#
# Date		| By			| Changes/New features
# ----------+---------------+-----------------------------------
# 2014/09/15 | Andreo		| Script Creation
# 2014/10/20 | Andreo		| Layout changes, and small additions
# 2015/04/09 | Andreo		| Get list of HFs deployed by Environment/Product
# 2016/03/01 | Andreo		| Updated display method, get last HFs after last refresh date
# 2016/04/25 | Andreo		| Removed the dependency with the properties file."
#===============================================================

# Setting the properties of the script. The below values need to be changed according to the HFtool DB information of the account.
{
export HOTFIX_UNIX_USER="/vivnas/viv/vivtools"
export HOTFIX_DIRECTORIES="${HOTFIX_UNIX_USER}/hotfix/HOTFIX"
export HOTFIX_HOST="indlin3554"
export HOTFIX_DB_USER="tooladm"
export HOTFIX_DB_PASSWORD="tooladm"
export HOTFIX_DB_INSTANCE="VV9TOOLS"
export HOTFIX_DEFAULT_DATE=$(date +%d/%m/%Y)
export HOTFIX_DEFAULT_DAYS_FOR_ENV_DEPLOY_HISTORY="35"
}

# Setting other variables and definitions used by the script
{
export VIRTUAL_MACHINE_NAME="indlnqw"
export SCRIPTS_DIRECTORIES="${HOTFIX_UNIX_USER}/scripts"
export SCRIPTS_DEPLOY_PROPERTIES="${SCRIPTS_DIRECTORIES}/getHotFixDetailsPropertiesFile.txt"
export TEMP_FILE="/tmp/getHotFixTempFile_$$.txt"
export TEMP_FILE_DETAILS="/tmp/getHotFixDetails_$$.txt"
export TEMP_FILE_COMMENTS="/tmp/getHotFixComments_$$.txt"
export TEMP_FILE_DEPLOY_INSTRUCTION="/tmp/getHotFixDeployInstructions_$$.txt"
export TEMP_FILE_DEPLOY_HISTORY="/tmp/getHotFixDeployHistory_$$.txt"
export TEMP_WORKING_FILE="/tmp/getHotFixEachFileDeployInstruction_$$.txt"
export RUN_MODE=""

export BLACK=$(tput setaf 0)
export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export YELLOW=$(tput setaf 3)
export LIME_YELLOW=$(tput setaf 190)
export POWDER_BLUE=$(tput setaf 153)
export BLUE=$(tput setaf 4)
export MAGENTA=$(tput setaf 5)
export CYAN=$(tput setaf 6)
export WHITE=$(tput setaf 7)
export BRIGHT=$(tput bold)
export NORMAL=$(tput sgr0)
export BLINK=$(tput blink)
export REVERSE=$(tput smso)
export UNDERLINE=$(tput smul)
}

# Checking if the script is being used correctly
usage(){
	printf "${RED}${BRIGHT}%s${NORMAL}\n" "Incorrect Usage !" 
	printf "${BRIGHT}%s${NORMAL}\n" "Correct Usage:"
	printf "\t%s\n" "$0 -h <HOTFIX NUMBER> (Lists deploy history of HF)"
	printf "\t%s\n" "$0 -e|-ve <ENVIRONMENT NUMBER> (List HFs deployed in the last ${HOTFIX_DEFAULT_DAYS_FOR_ENV_DEPLOY_HISTORY} days)"
	printf "\t%s\n" "$0 -e|-ve <ENVIRONMENT NUMBER> -d <NUMBER OF DAYS> (List HFs deployed in the last especified days)"
	printf "${GREEN}${BRIGHT}%s${NORMAL}\n" "Example:"
	printf "\t%s\n" "$0 -h 500010298"
	printf "\t%s\n" "$0 -e 10"
	printf "\t%s\n" "$0 -ve 12"
}

if [[ $# -lt 2 ]]
then
	usage
	exit 1
fi

# Functions that will be used on the script

# This functions gets the hotfixes per environment
getEnvDeployHistory(){
	environment="$1"
	sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
		SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
		select distinct unique_id as "Hotfix Number", environment as "Environment", last_modified_by as "Deployed by", event_name as "Status", to_char(creation_date, 'YYYY-MM-DD, HH24:MI') as "Deploy Date"
		from hotfix_evt
		where environment in (select environment from hotfix_environments where environment = '$environment')
		and trunc (creation_date) >= TO_DATE('$HOTFIX_DEFAULT_DATE', 'DD/MM/YYYY') - ${HOTFIX_DEFAULT_DAYS_FOR_ENV_DEPLOY_HISTORY}
		order by 5;
SQL
}

# This functions gets all the AD steps of the AD hotfixes. 1 AD step = 3 output lines.
getHFADInstructions(){
	sqlplus ${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE} << SQL
		SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
		select 'HOTFIX DEPLOY TYPE=' || HF_AD_DATA.deploy_type||(chr(10))|| 'HOTFIX DEPLOY FILE NAME=' || HF_AD_DATA.deploy_file||(chr(10))|| 'HOTFIX DEPLOY PATH=' || HF_AD_DATA.deploy_path
		from HOTFIX_AUTO_DEPLOY HF_AD_DATA
		where HF_AD_DATA.unique_id='$hotfix_id';
		exit
SQL
}

# This functions gets some HOTFIX Information from the HFtool
getHFDetails(){
	sqlplus ${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE} << SQL
		SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
		select
		'HOTFIX PRODUCT' || CHR(9) || CHR(9) || '= ' || HF_DESCRIPTION.product || (chr(10)) || 
		'HOTFIX VERSION' || CHR(9) || CHR(9) || '= ' || HF_DESCRIPTION.release || (chr(10)) || 
		'HOTFIX NUMBER' || CHR(9) || CHR(9) || '= ' || HF_DESCRIPTION.unique_id || (chr(10)) || 
		'HOTFIX CONTACT PERSON' || CHR(9) || '= ' || HF_DESCRIPTION.contact_person || (chr(10)) ||
		'HOTFIX TASK or REASON' || CHR(9) || '= ' || HF_DESCRIPTION.task_or_reason
		from HOTFIX_MNG HF_DESCRIPTION
		where HF_DESCRIPTION.unique_id='$hotfix_id';
		exit
SQL
}

# This function gets all the history from the HOTFIX_EVT table
getHFDeployHistory(){
	sqlplus ${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE} << SQL
		SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF SET LONG 10000000;
		select 'HOTFIX EVENT_NAME=' || event_name ||(chr(10))||
		'HOTFIX ENVIRONMENT=' || environment ||(chr(10))||
		'HOTFIX USER=' || last_modified_by ||(chr(10))||
		'HOTFIX EVENT DATE=' || to_char(creation_date, 'DD-MM-YYYY, HH24:MI') ||(chr(10))||
		'HOTFIX FILE NAME=' || file_name
		from  hotfix_evt
		where unique_id='$hotfix_id'
		order by creation_date;
		exit
SQL
}

# This function shows all the files of HFS that have only manual steps (no AD steps and only instructions)
getHFManualInstructions(){
	sqlplus ${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE} << SQL
		SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
		select 'HOTFIX DEPLOY TYPE=MANUAL'|| (chr(10)) || 'HOTFIX DEPLOY FILE NAME=' || file_name ||  (chr(10))|| 'HOTFIX DEPLOY PATH=MANUAL'	 
		FROM (	select *
				from hotfix_files
				where unique_id='$hotfix_id' 
				minus
				select a.* from hotfix_files a,hotfix_auto_deploy b where a.unique_id=b.unique_id and a.file_name=b.deploy_file 
				);
		exit
SQL
}  > ${TEMP_FILE_DEPLOY_INSTRUCTION}

# This function gets the value from the deploy parameters.
getValueDeployMethod(){
	deploy_type=$1
	product=$2
	sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
	SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
	select run_params from hotfix_deploy_methods where name='${deploy_type}' and product_id='${product}';
SQL
}

# This function gets the virtual machine environments
getVirtualEnvProducts(){
	sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
	SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
	select distinct environment from hotfix_environments where environment like '%inglnqw%${machine_number}';
SQL
}

# This function formats the output of the hotfixes per environment
formatOutputEnvDeployHistory(){
	printf "${BLUE}${BRIGHT}%s${NORMAL}\n" "----- Getting the Hotfixes for $1"
	printf "${BLUE}${BRIGHT}\t%-14s\t%-22s\t%-10s\t%-15s\t%-20s${NORMAL}\n" "Hotfix Number" "Environment" "User" "Status" "Date"
	
	while read history_line
	do
		hostfix_number=$(echo ${history_line} | cut -d ' ' -f 1)
		environment=$(echo ${history_line} | cut -d ' ' -f 2)
		user=$(echo ${history_line} | cut -d ' ' -f 3)
		status=$(echo ${history_line} | cut -d ' ' -f 4)
		date=$(echo ${history_line} | cut -d ' ' -f 5-)
	if [[ "${status}" == "FAILED" ]]
	then
		printf "\t%-14s\t%-22s\t%-10s\t${RED}${BRIGHT}%-15s${NORMAL}\t%-20s\n" "${hostfix_number}" "${environment}" "${user}" "${status}" "${date}"
	else
		printf "\t%-14s\t%-22s\t%-10s\t${GREEN}${BRIGHT}%-15s${NORMAL}\t%-20s\n" "${hostfix_number}" "${environment}" "${user}" "${status}" "${date}"
	fi
	done < ${TEMP_FILE_DEPLOY_HISTORY}
	printf "\n"
}

# This function formats the deploy instructions of the HF
formatOutputHotfixDeployInstructions(){
	# Getting the HF instructions from the HF tool DB.
	printf "${BLUE}${BRIGHT}%s${NORMAL}\n" "-------- INSTRUCTIONS"
	current_step=0
	hotfix_ad_steps=`grep -c "HOTFIX DEPLOY TYPE" ${TEMP_FILE_DEPLOY_INSTRUCTION}`

	# If the HF has neither AD steps, nor any HF files. It sets the below values.
	if [[ ${hotfix_ad_steps} -eq 0 ]]
	then
		echo "HOTFIX DEPLOY TYPE=MANUAL" > ${TEMP_FILE_DEPLOY_INSTRUCTION}
		echo "HOTFIX DEPLOY FILE NAME=N/A" >> ${TEMP_FILE_DEPLOY_INSTRUCTION}
		echo "HOTFIX DEPLOY PATH=MANUAL" >> ${TEMP_FILE_DEPLOY_INSTRUCTION}
		hotfix_ad_steps=`grep -c "HOTFIX DEPLOY TYPE" ${TEMP_FILE_DEPLOY_INSTRUCTION}`
	fi	
	
	# Filtering the output from the getHFADInstructions or getHFManualInstructions, and grouping each file in 3 lines.
	grep HOTFIX ${TEMP_FILE_DEPLOY_INSTRUCTION} > ${TEMP_WORKING_FILE}
	mv ${TEMP_WORKING_FILE} ${TEMP_FILE_DEPLOY_INSTRUCTION}
	
	# Looping through all the files.
	# Each file/AD instructions, has 3 lines on the file TEMP_FILE_DEPLOY_INSTRUCTION
	
	while [[ ${current_step} -lt ${hotfix_ad_steps} ]]
	do
		current_step=$(( ${current_step} + 1 ))
		# Getting the 3 lines per AD step, and sending it to a temporary file.
		sed -n $(( ${current_step} * 3 - 2 )),$(( ${current_step} * 3 ))p ${TEMP_FILE_DEPLOY_INSTRUCTION} > ${TEMP_WORKING_FILE}
		
		hotfix_deploy_type=`grep "HOTFIX DEPLOY TYPE" ${TEMP_WORKING_FILE} | cut -d '=' -f 2`
		hotfix_deploy_file=`grep "HOTFIX DEPLOY FILE NAME" ${TEMP_WORKING_FILE} | cut -d '=' -f 2`
		hotfix_deploy_path=`grep "HOTFIX DEPLOY PATH" ${TEMP_WORKING_FILE} | cut -d '=' -f 2`		
		case $hotfix_deploy_type in
			COPY )
				hotfix_deploy_type="CODE - Copy"		
				if [[ $hotfix_deploy_path == "For_APX_Index_HF" ]]
				then
					hotfix_deploy_path="AMSearch/amsearch-support/data/MainSystem1 or AMSearch/amsearch-support/data/MainSystem2"
				fi
			;;
			*)
				#Getting the translation values from the .properties file. That file is used to translate to strings to a more easy, but high level, text.
				if [[ ${hotfix_deploy_path} == "APX_INDEX_FILES" ]]
				then
					hotfix_deploy_file="N/A"
				fi
				if [[ ${hotfix_deploy_path} == "CONF_VIA_GENESIS" && ${hotfix_product} == "OPX" ]]
				then
					hotfix_deploy_file="N/A"
				fi
				getValueDeployMethod ${hotfix_deploy_path} ${hotfix_product} > ${TEMP_FILE}
					perl -pi -e "s/^\n//" ${TEMP_FILE}
				if [[ ! -e ${TEMP_FILE} ]]
				then
					hotfix_deploy_path=`cat ${TEMP_FILE}`
				fi
			;;
		esac
		
		printf "%s\n" "HOTFIX DEPLOY TYPE          = ${hotfix_deploy_type}"
		printf "%s\n" "HOTFIX DEPLOY FILE          = ${hotfix_deploy_file}"
		printf "%s\n" "HOTFIX DEPLOY DESTINATION   = ${hotfix_deploy_path}"
	done
	printf "\n"
}

# This function formats the output of the history of the HF
formatOutputHotfixHistory(){
	# Getting the HF history from the HF tool DB
	printf "${BLUE}${BRIGHT}%s${NORMAL}\n" "-------- HOTFIX HISTORY"
	grep HOTFIX ${TEMP_FILE_DEPLOY_HISTORY} > ${TEMP_WORKING_FILE}
	mv ${TEMP_WORKING_FILE} ${TEMP_FILE_DEPLOY_HISTORY}
	hotfix_events_quantity=`grep -c "HOTFIX ENVIRONMENT" ${TEMP_FILE_DEPLOY_HISTORY}`
	current_step=0

	printf "%-10s\t%-23s\t%-15s\t%-20s\t%s\n" "EVENT_NAME" "ENVIRONMENT" "USER" "EVENT_DATE" "FILE_NAME"

	while [[ ${current_step} -lt ${hotfix_events_quantity} ]]
	do
		current_step=$(( ${current_step} + 1 ))
		# Getting the 5 lines per events, and sending it to a temporary file.
		sed -n $(( ${current_step} * 5 - 4 )),$(( ${current_step} * 5 ))p ${TEMP_FILE_DEPLOY_HISTORY} > ${TEMP_WORKING_FILE}
		hotfix_event_name=`grep "HOTFIX EVENT_NAME" ${TEMP_WORKING_FILE} | cut -d '=' -f 2`
		hotfix_environment=`grep "HOTFIX ENVIRONMENT" ${TEMP_WORKING_FILE} | cut -d '=' -f 2`
		hotfix_user=`grep "HOTFIX USER" ${TEMP_WORKING_FILE} | cut -d '=' -f 2`
		hotfix_event_date=`grep "HOTFIX EVENT DATE" ${TEMP_WORKING_FILE} | cut -d '=' -f 2`
		hotfix_file_name=`grep "HOTFIX FILE NAME" ${TEMP_WORKING_FILE} | cut -d '=' -f 2`
		
		case ${hotfix_event_name} in 
			"FAILED") color=${RED} ;;
			"DEPLOYED") color=${GREEN} ;;
			"MODIFIED")	color=${YELLOW} ;;
			*) color=${NORMAL} ;;
		esac
		
		printf "${color}${BRIGHT}%-10s${NORMAL}\t%-23s\t%-15s\t%-20s\t%s\n" "${hotfix_event_name}" "${hotfix_environment}" "${hotfix_user}" "${hotfix_event_date}" "${hotfix_file_name}"
	done
	printf "\n"
}

# This function is used to format summarized details of the HF
formatOutputHotfixHighLevel(){
	# Getting some values from the HF, will be used to define the original location of the file on the HFtool structure.
	hotfix_product=`grep "HOTFIX PRODUCT" ${TEMP_FILE_DETAILS} | cut -d '=' -f 2 | cut -c 2-`
	hotfix_version_number=`grep "HOTFIX VERSION" ${TEMP_FILE_DETAILS} | cut -d '=' -f 2 | cut -c 2-`
	hotfix_number=`grep "HOTFIX NUMBER" ${TEMP_FILE_DETAILS} | cut -d '=' -f 2 | cut -c 2-`
	hotfix_file_location="${HOTFIX_DIRECTORIES}/${hotfix_product}/Release_${hotfix_version_number}/HF_${hotfix_number}"
	hotfix_readme_file_location="${hotfix_file_location}/HF_${hotfix_number}.README.txt"
	hotfix_status="AVAILABLE"
	
	# Printing the Product, Version, Number, Instructions, Comments
	printf "${BLUE}${BRIGHT}%s${NORMAL}\n" "-------- HF Details"
	grep "HOTFIX" ${TEMP_FILE_DETAILS} | sed 's/\&#13;/\n                          /g' | sed '/^\s*$/d'
	
	readme_instruction_start=$(grep -n "Instructions:" ${hotfix_readme_file_location} | cut -d ':' -f 1)
	readme_instruction_end=`grep -n "Comments/Test Plan:" ${hotfix_readme_file_location} | cut -d ':' -f 1`
	readme_comments_start=`grep -n "Comments/Test Plan:" ${hotfix_readme_file_location} | cut -d ':' -f 1`
	readme_comments_end=`grep -n "Defects:" ${hotfix_readme_file_location} | cut -d ':' -f 1`
	sed -n ${readme_instruction_start},$(( ${readme_instruction_end} -1 ))p ${hotfix_readme_file_location} > ${TEMP_FILE_COMMENTS}
	number_of_lines=`wc -l ${TEMP_FILE_COMMENTS} | awk '{print $1}'`
	if [[ ${number_of_lines} -lt 2 ]]
	then
		cat ${TEMP_FILE_COMMENTS} | sed 's/Instructions:/HOTFIX INSTRUCTIONS     =/g'
	else
		head -1 ${TEMP_FILE_COMMENTS} | sed 's/Instructions:/HOTFIX INSTRUCTIONS     =/g'
		tail -$(( ${number_of_lines} -1 )) ${TEMP_FILE_COMMENTS} | sed 's/^/                          /g'  | sed '/^\s*$/d'
	fi
	
	sed -n ${readme_comments_start},$(( ${readme_comments_end} -1 ))p ${hotfix_readme_file_location} > ${TEMP_FILE_COMMENTS}
	number_of_lines=`wc -l ${TEMP_FILE_COMMENTS} | awk '{print $1}'`
	if [[ ${number_of_lines} -lt 2 ]]
	then
		cat ${TEMP_FILE_COMMENTS} | sed 's/Comments\/Test Plan:/HOTFIX COMMENTS         =/g'
	else
		head -1 ${TEMP_FILE_COMMENTS} | sed 's/Comments\/Test Plan:/HOTFIX COMMENTS         =/g'
		tail -$(( ${number_of_lines} -1 )) ${TEMP_FILE_COMMENTS} | sed 's/^/                          /g'  | sed '/^\s*$/d'
	fi

	printf "%s\n" "HOTFIX FILE LOCATION    = ${hotfix_file_location}"
	printf "%s\n" "HOTFIX FILE HOST        = ${HOTFIX_HOST}"	
	
	if [[ `grep -c "REJECTED" ${TEMP_FILE_DEPLOY_HISTORY}` -gt 0 ]]
	then
		printf "%s${RED}${BRIGHT}%s${NORMAL}\n" "HOTFIX STATUS           = " "REJECTED"
	else
		printf "%s${GREEN}${BRIGHT}%s${NORMAL}\n" "HOTFIX STATUS           = " "DEPLOYED"
	fi
	printf "\n"
}

# This function verifies if the Environment Exists exists on the HFTool Database
checkEnvExistance(){
	sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
	SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
	select distinct environment from hotfix_environments where environment like '______${environment_number}@%' and environment not like '%${VIRTUAL_MACHINE_NAME}%';
SQL
}

# This function verifies if the HF exists on the HFTool Database
checkHFExistance(){
	hotfix_product=`grep "HOTFIX PRODUCT" ${TEMP_FILE_DETAILS} | cut -d '=' -f 2 | cut -c 2-`
	hotfix_version_number=`grep "HOTFIX VERSION" ${TEMP_FILE_DETAILS} | cut -d '=' -f 2 | cut -c 2-`
	hotfix_number=`grep "HOTFIX NUMBER" ${TEMP_FILE_DETAILS} | cut -d '=' -f 2 | cut -c 2-`
	hotfix_file_location="${HOTFIX_DIRECTORIES}/${hotfix_product}/Release_${hotfix_version_number}/HF_${hotfix_number}"
	hotfix_readme_file_location="${hotfix_file_location}/HF_${hotfix_number}.README.txt"
	if [[ ! `grep -c "HOTFIX PRODUCT" ${TEMP_FILE_DETAILS}` -gt 0 ]]
	then
		printf "${RED}${BRIGHT}%s\n${NORMAL}" "The HOTFIX ${hotfix_id} does not exist in the DB or the HFs were not synched yet!"
		exit 
	fi
	
	if [[ ! -e ${hotfix_readme_file_location} ]]
	then
	printf "${RED}${BRIGHT}%s\n${NORMAL}" "The HOTFIX ${hotfix_id} instruction file was not found in the unix side!"
	exit 
	fi
	
}

# This function verifies if the Virtual Environment Exists exists on the HFTool Database
checkVEnvExistance(){
	sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
	SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
	select distinct environment from hotfix_environments where environment like '%${VIRTUAL_MACHINE_NAME}%${machine_number}';
SQL
}

# This functions remove the temporary files that were created
cleanTempFiles(){
	rm -f ${TEMP_FILE}
	rm -f ${TEMP_FILE_DETAILS}
	rm -f ${TEMP_FILE_DEPLOY_INSTRUCTION}
	rm -f ${TEMP_WORKING_FILE}
	rm -f ${TEMP_FILE_DEPLOY_HISTORY}
	rm -f ${TEMP_FILE_COMMENTS}
}

######################################################
##           Main execution of the script           ##
######################################################

# Reading the script input parameters.
export RUN_MODE="$1"
export RUN_PARAMETER="$2"

clear
# Calling the appropriate methods according to the run mode
case $RUN_MODE in
	-h)
		export hotfix_id="${RUN_PARAMETER}"
		getHFDetails > ${TEMP_FILE_DETAILS}
		checkHFExistance

		getHFADInstructions  > ${TEMP_FILE_DEPLOY_INSTRUCTION}
			grep HOTFIX ${TEMP_FILE_DEPLOY_INSTRUCTION} > ${TEMP_WORKING_FILE}

		getHFManualInstructions > ${TEMP_FILE_DEPLOY_INSTRUCTION}
			grep HOTFIX ${TEMP_FILE_DEPLOY_INSTRUCTION} >> ${TEMP_WORKING_FILE}
			mv ${TEMP_WORKING_FILE} ${TEMP_FILE_DEPLOY_INSTRUCTION}

		getHFDeployHistory > ${TEMP_FILE_DEPLOY_HISTORY}
		
		formatOutputHotfixHighLevel
		formatOutputHotfixDeployInstructions
		formatOutputHotfixHistory
	;;
	-e)
		export environment_number="${RUN_PARAMETER}"
		checkEnvExistance > ${TEMP_FILE_DETAILS}
		perl -pi -e "s/^\n//" ${TEMP_FILE_DETAILS}
		if [[ ! -s ${TEMP_FILE_DETAILS} ]]
		then
			printf "${RED}${BRIGHT}%s\n${NORMAL}" "Environment does not exist!"
			exit 0
		fi
		
		shift 2
		if [[ $1 == "-d" ]]
		then
			export HOTFIX_DEFAULT_DAYS_FOR_ENV_DEPLOY_HISTORY = "$2"
		fi
		
		while read productServer
		do
			getEnvDeployHistory $productServer > ${TEMP_FILE_DEPLOY_HISTORY}
			perl -pi -e "s/^\n//" ${TEMP_FILE_DEPLOY_HISTORY}
			formatOutputEnvDeployHistory $productServer
		done < ${TEMP_FILE_DETAILS}
	;;
	-ve)
		export machine_number="${RUN_PARAMETER}"
		checkVEnvExistance > ${TEMP_FILE_DETAILS}
		if [[ ! -s ${TEMP_FILE_DETAILS} ]]
		then
			printf "${RED}${BRIGHT}%s\n${NORMAL}" "Virtual environment does not exist!"
			exit 0
		fi
		shift 2
		if [[ $1 == "-d" ]]
		then
			export HOTFIX_DEFAULT_DAYS_FOR_ENV_DEPLOY_HISTORY="$2"
		fi
		getVirtualEnvProducts > ${TEMP_FILE_DETAILS}
		perl -pi -e "s/^\n//" ${TEMP_FILE_DETAILS}
		while read productServer
		do
			getEnvDeployHistory $productServer > ${TEMP_FILE_DEPLOY_HISTORY}
			perl -pi -e "s/^\n//" ${TEMP_FILE_DEPLOY_HISTORY}
			formatOutputEnvDeployHistory $productServer
		done < ${TEMP_FILE_DETAILS}
	;;
	*)
		usage
		exit 1
	;;
esac

cleanTempFiles
