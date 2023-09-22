#!/usr/bin/env ksh
# Pedro Pavan

if [[ "${USER}" != *"abp"* ]]; then
    echo -e "This is not ABP account!\nExiting..."
    exit 1
fi

check() {
	if [ $? -ne 0 ]; then
		echo -e "$1!\nExiting..."
		exit 1
	fi
}

# Copy to local temp dir
TMP_FOLDER="${HOME}/.uams_$(date +%Y%m%d%H%M%S)_$$"
mkdir -v ${TMP_FOLDER}
#cp -rf /vivnas/viv/vivtools/users/pedrop/UAMS/uams.tar.gz ${TMP_FOLDER}/
cp -rf /vivnas/viv/vivtools//Scripts/UAMS/uams.tar.gz ${TMP_FOLDER}/

cd ${TMP_FOLDER}/
tar xvf uams.tar.gz ; rm -f uams.tar.gz 2> /dev/null

# Take a backup of current users (DB) 
cd ${TMP_FOLDER}/
SECO_USER=$(echo ${SEC_DB_USER} | sed 's/SEC/SECO/g')
SECO_PASS=$(echo ${SEC_DB_PASS} | sed 's/SEC/SECO/g')
exp ${SECO_USER}/${SECO_PASS}@${SEC_DB_INST} tables="SEC_USER" file="SEC_USER.dmp" log="SEC_USER.log" buffer=1024000 statistics=none
check "Failed to take backup"

# Users
echo "
SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
SELECT user_id FROM sec_user ORDER BY 1 ASC;
" | sqlplus -S ${SEC_DB_USER}/${SEC_DB_PASS}@${SEC_DB_INST} | egrep -v "^#|^$" > users.txt
check "Failed to get user list"

if [ ! -s users.txt ]; then 
	echo -e "User list is empty!\nAborting"
	exit 2
fi

# Properties
echo "
############################################################
# Property file uams.properties
# This file was generated automatically by Pedro Pavan
############################################################
SEC_DB_INST=${SEC_DB_INST}
SEC_DB_PORT=1521
SEC_DB_USER=${SEC_DB_USER}
SEC_DB_PWD=${SEC_DB_PASS}
SEC_DB_HOST=${APP_DB_NODE}
WL9_DISABLED=1
" > uams.properties 

# Run UAMS command
java -classpath "asm_sample_tools.jar:uams.jar:ojdbc6.jar" -Damdocs.uams.config.print=true -Damdocs.system.home=$(pwd)/ -Damdocs.uams.config.resource=res/gen/secsrv -Damdocs.uams.startup.password=none com.amdocs.asm.sample.tools.BulkUserAdmin -userFile users.txt -adminPassword Root00 -setPasswordExpiration 0
check "Failed to set new password expiration"

echo "

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

echo "
SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
column USERNAME format a40;
select USER_ID as USERNAME, replace(CRED_EXPIRATION_DATE, '01-JAN-70', 'NEVER EXPIRES') as EXPIRATION_DATE from SEC_USER;
" | sqlplus -S ${SEC_DB_USER}/${SEC_DB_PASS}@${SEC_DB_INST} | egrep -v "^#|^$"

exit 0
