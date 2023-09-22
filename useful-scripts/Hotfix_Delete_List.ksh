#!/usr/bin/env ksh

if [ $# -ne 1 ]; then
	echo -e "Missing parameter!\nExiting..."
	exit 1
fi

HF_LIST=$1
HF_LIST_TMP=$(mktemp /tmp/hf_delete_$$_XXXXX.tmp)

if [ ! -f ${HF_LIST} ]; then
	echo -e "File not found!\nExiting..."
	exit 2
fi

print "
SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
SELECT UNIQUE_ID AS HF_ID, PRODUCT AS PRODUCT, RELEASE AS VERSION
  FROM HOTFIX_MNG
WHERE UNIQUE_ID IN (
	$(cat ${HF_LIST} | tr '\n' ',' | rev | cut -c 2- | rev)
); " | sqlplus -S ${TOOLS_DB_USER}/${TOOLS_DB_PASSWORD}@${TOOLS_DB_INSTANCE} | egrep -v "^#|^$" > ${HF_LIST_TMP}

LOG_FILE="$(basename $0).log"
> ${LOG_FILE}

while read line ; do
	HF_ID=$(echo ${line} | awk '{ print $1 }')
	HF_PRODUCT=$(echo ${line} | awk '{ print $2 }')
	HF_VERSION=$(echo ${line} | awk '{ print $3 }')

	echo "Removing ${HF_ID}"
	${HOME}/hotfix/Hotfix_Removal.ksh -hf_id ${HF_ID} -product ${HF_PRODUCT} -version ${HF_VERSION} >> ${LOG_FILE} 2>&1
done < ${HF_LIST_TMP}

print "Please check the log: ${LOG_FILE}"
rm ${HF_LIST_TMP}
exit 0
