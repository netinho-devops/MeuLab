#!/bin/ksh
#===============================================================
# NAME      :  MWLM.ksh
# Programmer:  Pedro Pavan
# Date      :  24-Nov-16
# Purpose   :  Deploy HFs on window maintenance
#
# Changes history:
#
#  Date     |    By       | Changes/New features
# ----------+-------------+-------------------------------------
# 11-24-16    Pedro Pavan   Initial version
# 12-01-16    Pedro Pavan   Support Manual HF
# 12-08-16    Pedro Pavan	Full bounce improved
# 12-21-16	  Pedro Pavan   Colors
# 01-18-17    Willian Costa Killing ABP processes
# 01-25-17	  Pedro Pavan   Bundle information
#===============================================================

######################################
# Temporary files
######################################
ENV_PRODUCT_LIST="$(mktemp /tmp/$(basename $0)_$$_XXXXXXXXXX.tmp)"
ENV_PRODUCT_LIST_ALL="$(mktemp /tmp/$(basename $0)_$$_XXXXXXXXXX.tmp)"
PRODUCT_LIST="$(mktemp /tmp/$(basename $0)_$$_XXXXXXXXXX.tmp)"
PRODUCT_LIST_ALL="$(mktemp /tmp/$(basename $0)_$$_XXXXXXXXXX.tmp)"
TEMP_LIST1="$(mktemp /tmp/$(basename $0)_$$_XXXXXXXXXX.tmp)"
TEMP_LIST2="$(mktemp /tmp/$(basename $0)_$$_XXXXXXXXXX.tmp)"
MANUAL_HFS="$(mktemp /tmp/$(basename $0)_$$_XXXXXXXXXX.tmp)"

######################################
# Colors
######################################
export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export YELLOW=$(tput setaf 3)
export BLUE=$(tput setaf 4)
export WHITE=$(tput setaf 7)
export BRIGHT=$(tput bold)
export NORMAL=$(tput sgr0)

######################################
# Usage
######################################
Usage() {
    EXIT_CODE=$1

    echo ""
    echo "Usage: $(basename $0) -e <environment> -b <bundle1,bundle2,bundleN>"
    echo ""

    exit ${EXIT_CODE}
}

######################################
# Message
######################################
Message() {
	MSG="$1"
	print ""
	print "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	print "@@@ $(echo ${MSG} | tr '[a-z]' '[A-Z]')"
	print "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	sleep 1
}

######################################
# Check status of last command
######################################
Status() {
	if [ $? -ne 0 ]; then
		echo -e "Previous operation has finished with errors!\nAborting..."
		exit 99
	else
		echo DONE
	fi
}

######################################
# HF Tool DB
######################################
Get_Genesis_DB() {
    echo "$AMC_REPOSITORY_DATABASE_USERNAME/$AMC_REPOSITORY_DATABASE_PASSWORD@$AMC_REPOSITORY_DATABASE_INSTANCE"
}

######################################
# Fetch list of products & unix accounts 
######################################
Get_Env_List(){
    bundle=$2
    environment_number=$1
	full=${3:-N}

	if [ "${full}" == "Y" ]; then
		PRODUCT_QUERY="('ABP', 'CRM', 'OMS')"
	else
		PRODUCT_QUERY="(SELECT DISTINCT product FROM hotfix_mng WHERE unique_id IN (SELECT unique_id FROM hotfix_bundles WHERE bundle_name IN ('${bundle}')))"
	fi

	print "
    SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;

	SELECT product, environment 
	  FROM hotfix_ctl
	 WHERE product IN ${PRODUCT_QUERY}
	   AND environment LIKE '%@indlnqw${environment_number}';" | sqlplus -s $(Get_Genesis_DB) | egrep -v "^#|^$"
}

######################################
# Get unix details
######################################
Product_Info() {
	product=$1
	env=$2

    echo "
		SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
		SELECT environment FROM HOTFIX_CTL WHERE product = '${product}' AND environment LIKE '%@indlnqw${env}';
	" | sqlplus -s $(Get_Genesis_DB) | egrep -v "^#|^$"	
}

######################################
# Fetch bundle details
######################################
Bundle_Info() {
	echo -e "\nBundle information"

	for bundle in $(echo ${BUNDLES} | tr ',' '\n'); do
		print "
	    SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
		
		SELECT BDL.bundle_name, 
		       BDL.order_num,
		       BDL.unique_id,
		       MNG.product,
			   MNG.release, 
		       DECODE((SELECT COUNT(BDL.unique_id) FROM hotfix_mng WHERE BDL.unique_id = unique_id AND unique_id NOT IN (SELECT unique_id FROM hotfix_auto_deploy)),
		          0, 'AUTO',
		          1, 'MANUAL',
		          'NA') AS AUTO_DEPLOY,
	           MNG.fix_type
		 FROM hotfix_bundles BDL
		INNER JOIN hotfix_mng MNG ON MNG.unique_id = BDL.unique_id
		WHERE BDL.bundle_name IN ('${bundle}')
		ORDER BY BDL.bundle_name, BDL.order_num ASC;
		" | sqlplus -s $(Get_Genesis_DB) | egrep -v "^#|^$" | awk '{ print "- "$1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7 }' | tee ${MANUAL_HFS}
	done
}

######################################
# Information before deployment
######################################
Deployment_Info() {

	export ENV_PHASE=$(echo "
	 	SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;	
		select distinct testing_phase from ENSPOOL where property = 'Owner' and signature like '%@indlnqw${TARGET_ENV}';" | sqlplus -s $(Get_Genesis_DB) | egrep -v "^#|^$" | sort | uniq | head -n 1)

	echo -e "What will be done\n- Environment: $(echo ${ENV_PHASE} | sed 's/APP/UAT/g')#${TARGET_ENV}"
	echo -e "- Bundles: "

	bundle_count=0
	
	for bundle in $(echo ${BUNDLES} | tr ',' '\n'); do 
		bundle_count=$(expr ${bundle_count} + 1)
		echo -e "\t(${bundle_count}) ${bundle}"
	done

	echo "- Systems impacted: "
	
	product_count=0

	for product in $(cat ${PRODUCT_LIST} | sed 's/SE/OMS/g' | sed 's/EPC-//g' | sort | uniq); do
		product_count=$(expr ${product_count} + 1)
		echo -ne "\t(${product_count}) ${product} - "
		Product_Info ${product} ${TARGET_ENV}
	done

	echo "- Restart required: $(cat ${TARGET_PRODUCT} | sed 's/SE/OMS/g' | sed 's/EPC-//g' | sort | uniq | tr '\n' ',' | rev | cut -c 2- | rev | sed 's/,/, /g')"
}


######################################
# Validate if bundle exists
######################################
Bundle_Exits() {
	bundle=$1

	count=$(echo "
	 	SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;	
		select count(1) from hotfix_bundles where bundle_name = '${bundle}';
	" | sqlplus -s $(Get_Genesis_DB) | egrep -v "^#|^$" | sed -e 's/^[ \t]*//')

	echo ${count} 
}

######################################
# Clean cache on specific account
######################################
Clean_Cache(){
	product=$1
	account=$2

	COMMAND="X"

	case ${product} in
		"ABP")	COMMAND="rm -rf ~/JEE/ABPProduct/WLS/ABP-FULL/servers/ABPServer/{cache,tmp}"						;;
		"CRM")	COMMAND="rm -rf ~/JEE/CRMProduct/WLS/*/servers/*/{cache,tmp}"										;;
		"OMS")	COMMAND="rm -rf ~/JEE/OMS/WLS/*/servers/*/{cache,tmp}"												;;
		"AMSS")	COMMAND="rm -rf ~/JEE/AMSSProduct/WLS/AMSSFullDomain/servers/AMSSFullServer/{cache,tmp}"			;;
		"OMNI")	COMMAND="rm -rf ~/JEE/LightSaberDomain/WLS/LightSaberDomain/servers/omni_LSJEE/{cache,tmp}"			;;
		"WSF")	COMMAND="rm -rf ~/deployment/WSF/apache-tomcat/apache-tomcat-a/webapps/wsf-app-war/ 2> /dev/null"	;;
	esac

	if [ "${COMMAND}" == "X" ]; then
		break
		echo "No cache for: ${product}"
	else
		echo "Cleaning cache on ${account}"
		ssh -n ${account} "${COMMAND}" 2> /dev/null
	fi
}

######################################
# Kill all processes
######################################
Kill_All(){
    account=$1
	ssh -n ${account} '/usr/bin/kill -9 -1' 2> /dev/null
}

######################################
# MAIN
######################################
while getopts ":e:b:h" opt
do
    case "${opt}" in
        e) TARGET_ENV=${OPTARG}     ;;
        b) BUNDLES=${OPTARG}        ;;
        h) Usage 0                  ;;
        *) Usage 1                  ;;
    esac
done

if [ $# -lt 4 ]; then
    Usage 1
fi

### 0. FETCH ALL DETAILS
SECONDS=0
Message "loading details"

if [[ ${BUNDLES} == *","* ]]; then
	for bundle in $(echo ${BUNDLES} | tr ',' '\n'); do
		if [ $(Bundle_Exits ${bundle}) -eq 0 ]; then
			echo -e "Bundle: ${bundle} does not exist!\nAborting..."
			exit 2
		fi

		Get_Env_List ${TARGET_ENV} ${bundle} >> ${TEMP_LIST1}
	done

	cat ${TEMP_LIST1} | sort | uniq > ${ENV_PRODUCT_LIST} 
else
	if [ $(Bundle_Exits ${BUNDLES}) -eq 0 ]; then
		echo -e "Bundle: ${BUNDLES} does not exist!\nAborting..."
		exit 2
	fi
	
	Get_Env_List ${TARGET_ENV} ${BUNDLES} > ${ENV_PRODUCT_LIST}
fi

if [ ! -s ${ENV_PRODUCT_LIST} ]; then
	echo -e "Information was not found for given environment!\nExiting..."
	exit 3
fi

cat ${ENV_PRODUCT_LIST} > ${TEMP_LIST2}
Get_Env_List ${TARGET_ENV} ${BUNDLES} Y >> ${TEMP_LIST2}
cat ${TEMP_LIST2} | sort | uniq > ${ENV_PRODUCT_LIST_ALL}

cat ${ENV_PRODUCT_LIST} | awk '{ print $1 }' > ${PRODUCT_LIST}
cat ${ENV_PRODUCT_LIST_ALL} | awk '{ print $1 }' > ${PRODUCT_LIST_ALL}

FULL_BOUNCE_REQUIRED=$(grep -c "ABP" ${PRODUCT_LIST})

if [ ${FULL_BOUNCE_REQUIRED} -eq 0 ]; then
	TARGET_LIST="${ENV_PRODUCT_LIST}"
	TARGET_PRODUCT="${PRODUCT_LIST}"
else
	TARGET_LIST="${ENV_PRODUCT_LIST_ALL}"
	TARGET_PRODUCT="${PRODUCT_LIST_ALL}"
fi

Deployment_Info

Bundle_Info

echo -e "\nAre you ready for the challenge? Press any key to continue..."
read

### 1. BRING ENVIRONMENT DOWN
Message "stopping environment"

for product in $(cat ${TARGET_PRODUCT} | sed 's/SE/OMS/g' | sed 's/EPC-//g' | sort | uniq); do
	echo "Stopping ${product}"
	${HOME}/PIL/scripts/PCI1_BootManager_CommandLine.ksh --nomail STOP ${ENV_PHASE} indlnqw${TARGET_ENV} ${product} ALL 	| 
		sed "s/SUCCESS/${GREEN}${BRIGHT}SUCCESS${NORMAL}/g" 														|
		sed "s/TIMEOUT/${YELLOW}${BRIGHT}TIMEOUT${NORMAL}/g" 														|
		sed "s/ERROR/${RED}${BRIGHT}ERROR${NORMAL}/g"

	Status

	_account=$(cat ${TARGET_LIST} | grep ${product} | awk '{ print $2 }' | uniq)
	_processes=$(ssh ${_account} 'pgrep -U ${USER} | wc -l' 2> /dev/null)

	if [ ${_processes} -gt 2 ]; then
		echo "Killing remaining processes (${_processes})"
		Kill_All ${_account}
	fi
done

### 2. DEPLOY HOTFIXES
Message "Start HF deployment"
. ${HOME}/Scripts/hotfix/deploy/deployhf.ksh -ve ${TARGET_ENV} -b ${BUNDLES} -i -c -w
Status

### 3. CLEAN CACHE
Message "clean cache"
for line in $(cat ${TARGET_LIST} | awk '{ print $1":"$2 }' | sed 's/SE/OMS/g' | sed 's/EPC-//g' | sort | uniq); do
    _product=$(echo ${line} | cut -d ':' -f 1)
    _account=$(echo ${line} | cut -d ':' -f 2)
	Clean_Cache ${_product} ${_account}
done
Status

### 4. BRING ENVIRONMENT UP
Message "Start environment"
if [ "${MANUAL_HF_FOUND}" == "Y" ]; then
    echo "Bad news! Please deploy MANUAL HF(s) and press any key to continue."
    read

	for hf_id in $(cat ${MANUAL_HFS} | grep MANUAL | awk '{ print $4 }'); do 
		ksh ${HOME}/Scripts/hotfix/deploy/deployhf.ksh -ve ${TARGET_ENV} -md ${hf_id} -i -c > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "- Marked as deployed: ${hf_id}"
		else
			echo "- Failed to mark HF#${hf_id} as deployed, check it!"
		fi
	done
fi

echo -e "\nStarting, please wait"
${HOME}/PIL/scripts/PCI1_BootManager_CommandLine.ksh --nomail START ${ENV_PHASE} indlnqw${TARGET_ENV} ALL ALL		|
			sed "s/SUCCESS/${GREEN}${BRIGHT}SUCCESS${NORMAL}/g" 											|
			sed "s/TIMEOUT/${YELLOW}${BRIGHT}TIMEOUT${NORMAL}/g" 											|
			sed "s/CANCELED/${YELLOW}${BRIGHT}CANCELED${NORMAL}/g" 											|
			sed "s/ERROR/${RED}${BRIGHT}ERROR${NORMAL}/g"
Status

### 5. CHECK ENVIRONMENT STATUS
Message "Environment status"
${HOME}/PIL/scripts/PCI1_BootManager_CommandLine.ksh --nomail PING ${ENV_PHASE} indlnqw${TARGET_ENV} ALL ALL	|
			sed "s/UP/${GREEN}${BRIGHT}UP${NORMAL}/g" 													|
			sed "s/DOWN/${RED}${BRIGHT}DOWN${NORMAL}/g" 											
Status

### 6. CHECK ENVIRONMENT LOGS
Message "Environment logs"
for line in $(cat ${TARGET_LIST} | awk '{ print $1":"$2 }' | sed 's/SE/OMS/g' | sed 's/EPC-//g' | sort | uniq); do
    _product=$(echo ${line} | cut -d ':' -f 1)
    _account=$(echo ${line} | cut -d ':' -f 2)
	echo -ne "[${_product}] ${_account}: " 
	ssh -n ${_account} "/vivnas/viv/vivtools/Scripts/window/checkWebLogicLog.ksh" 2> /dev/null
done

### END OF SCRIPT
TIME_ELAPSED=$(echo ${SECONDS} | cut -d '.' -f 1)
print "
Time elapsed: $(expr ${TIME_ELAPSED} / 60) min
"
rm /tmp/$(basename $0)_$$* 2> /dev/null
exit 0
