#!/usr/bin/env ksh
#===============================================================
# NAME      :  HotfixCreateDailyBundle.ksh
# Programmer:  Pedro Pavan
# Date      :  29-Aug-16
# Purpose   :  Create daily bundle based on rules
#
# Changes history:
#
#  Date     |     By        | Changes/New features
# ----------+---------------+-----------------------------------
# 08-29-16    Pedro Pavan       Initial version
# 09-14-16    Pedro Pavan       Create full bundle
# 09-15-16    Pedro Pavan       Delete old bundles
#===============================================================

######################################
# Variables
######################################
DEBUG_MODE="ON"
KEEP_OLD_BUNDLES=${2:-3}
LOG_FILE="$(dirname $0)/$(basename $0 | sed 's/.ksh/.log/g')"

HF_LIST=$(mktemp /tmp/$(basename $0)_$$_XXXXXXXXXX.txt)
BUNDLE_LIST=$(mktemp /tmp/$(basename $0)_$$_XXXXXXXXXX.txt)

PREFIX_NAME_BUNDLE_DAILY="UAT_BUNDLE_DAILY_%version%"
PREFIX_NAME_BUNDLE_FULL="UAT_BUNDLE_FULL_%version%"

SQL_BUNDLE_DAILY_AD=$(mktemp /tmp/$(basename $0)_$$_XXXXXXXXXX.sql)
SQL_BUNDLE_DAILY_MANUAL=$(mktemp /tmp/$(basename $0)_$$_XXXXXXXXXX.sql)
SQL_BUNDLE_FULL=$(mktemp /tmp/$(basename $0)_$$_XXXXXXXXXX.sql)
SQL_BUNDLE_OLD=$(mktemp /tmp/$(basename $0)_$$_XXXXXXXXXX.sql)
SQL_BUNDLE_REJECTED=$(mktemp /tmp/$(basename $0)_$$_XXXXXXXXXX.sql)

######################################
# Usage
######################################
Usage() {
    EXIT_CODE=$1

    echo -e "Usage: \n"
    echo "$(basename $0) <hotfix_version> [<days>]"
    echo ""
    echo -e "\t1. hotfix_version: Choose release number"
    echo ""
	echo -e "\t2. days: keep old bundles (optional, default is 3)"
	echo ""

    exit ${EXIT_CODE}
}

######################################
# Debug message
######################################
Debug() {
	MESSAGE="$*"
	CUR_LINES=$(wc -l ${LOG_FILE} | awk '{ print $1 }')
	MAX_LINES=5000

	if [ ! -f ${LOG_FILE} ]; then
		touch ${LOG_FILE}
	fi

	if [ ${CUR_LINES} -gt ${MAX_LINES} ]; then
		sed -i -e '1,250d' ${LOG_FILE}
	fi

	if [ "${DEBUG_MODE}" == "ON" ]; then
		echo -e "$(date +'%D %T') <DEBUG> ${MESSAGE}" >> ${LOG_FILE}
	fi
}

######################################
# Fetch HF list
######################################
Fetch_HF_List() {

TARGET_DATE=$1

case "${TARGET_DATE}" in
	"today")	TARGET_DATE="$(date +%d/%m/%Y)"
				CONDITION="1=1"
	;;
	"all")		TARGET_DATE="01/01/2012"		
				CONDITION="1=1"
	;;
	"bundle")	TARGET_DATE="01/01/2012"
				CONDITION="unique_id in (SELECT unique_id FROM hotfix_bundles WHERE bundle_name = '${BUNDLE_FULL}')"
	;;
	"rejected")	TARGET_DATE="01/01/2012"
				CONDITION="unique_id in (SELECT unique_id FROM hotfix_evt WHERE event_name = 'REJECTED')"
	;;
esac

print "
WHENEVER SQLERROR EXIT 5
SET FEEDBACK OFF
SET HEADING OFF
SET PAGES 0
SET LINE 500

SELECT M.unique_id 
  FROM hotfix_mng M
 WHERE release = '${HF_VERSION}'
   AND creation_date > TO_DATE('${TARGET_DATE} 00:00:00', 'dd/mm/yyyy hh24:mi:ss')
   AND unique_id in (SELECT unique_id 
                       FROM hotfix_ap_relations
                      WHERE unique_id = M.unique_id
                        AND param_id = 6
                        AND param_value like 'YES%')
   AND ${CONDITION}
 ORDER BY M.unique_id ASC;
" | sqlplus -S ${TOOLS_DB_USER}/${TOOLS_DB_PASSWORD}@${TOOLS_DB_INSTANCE} | sed -e 's/^[ \t]*//' > ${HF_LIST}

Debug "Fetch_HF_List @ $(cat ${HF_LIST} | tr '\n' ' ')"
}

######################################
# Latest HF Order
######################################
Latest_HF_Order() {

print "
WHENEVER SQLERROR EXIT 5
SET FEEDBACK OFF
SET HEADING OFF
SET PAGES 0
SET LINE 500
SELECT NVL(MAX(order_num), 0) as total FROM hotfix_bundles WHERE bundle_name = '${BUNDLE_FULL}';
" | sqlplus -S ${TOOLS_DB_USER}/${TOOLS_DB_PASSWORD}@${TOOLS_DB_INSTANCE} | sed -e 's/^[ \t]*//'
}

######################################
# Check if HF is AD
######################################
is_AD() {
HF_ID=$1

print "
WHENEVER SQLERROR EXIT 5
SET FEEDBACK OFF
SET HEADING OFF
SET PAGES 0
SET LINE 500

SELECT DECODE((SELECT COUNT(UNIQUE_ID) FROM HOTFIX_MNG WHERE UNIQUE_ID = ${HF_ID} AND UNIQUE_ID NOT IN (SELECT UNIQUE_ID FROM HOTFIX_AUTO_DEPLOY)),
       0, 'YES',
       1, 'NO',
       'NO') AS STATUS FROM DUAL;
" | sqlplus -S ${TOOLS_DB_USER}/${TOOLS_DB_PASSWORD}@${TOOLS_DB_INSTANCE} | sed -e 's/^[ \t]*//'
}

# Latest bundle
#select BUNDLE_NAME from HOTFIX_BUNDLES where BUNDLE_NAME like 'SWP%_Bundle' order by SYS_CREATION_DATE desc;

######################################
# Run SQL Statement
######################################
Run_SQL_Statement() {

TARGET_FILE=$1

if [ -f ${TARGET_FILE} ]; then
	if [ -s ${TARGET_FILE} ]; then
		echo -e "\ncommit;" >> ${TARGET_FILE}
		Debug "Run_SQL_Statement @ Running below SQL:"
		cat ${TARGET_FILE} >> ${LOG_FILE}
 		#cat ${TARGET_FILE} | sqlplus -S ${TOOLS_DB_USER}/${TOOLS_DB_PASSWORD}@${TOOLS_DB_INSTANCE} >> ${LOG_FILE} 2>&1
	fi
fi

}

######################################
# Delete old bundles
######################################
Delete_Old_Bundles() {

echo "Deleting old bundles - keep last ${KEEP_OLD_BUNDLES} day(s)"

Debug "Delete_Old_Bundles @ Days: ${KEEP_OLD_BUNDLES}"

print "DELETE FROM hotfix_bundles WHERE bundle_name IN (SELECT DISTINCT bundle_name FROM hotfix_bundles WHERE bundle_name LIKE '$(echo ${PREFIX_NAME_BUNDLE_DAILY} | sed "s/%version%/${HF_VERSION}/g")%' AND sys_creation_date < (sysdate - ${KEEP_OLD_BUNDLES}));
DELETE FROM hotfix_bundles_status WHERE bundle_name IN (SELECT DISTINCT bundle_name FROM hotfix_bundles WHERE bundle_name LIKE '$(echo ${PREFIX_NAME_BUNDLE_DAILY} | sed "s/%version%/${HF_VERSION}/g")%' AND sys_creation_date < (sysdate - ${KEEP_OLD_BUNDLES}));" > ${SQL_BUNDLE_OLD}

Run_SQL_Statement ${SQL_BUNDLE_OLD}
}

######################################
# Create Bundle - Daily
######################################
Create_Daily_Bundle() {

Debug "Bundle: ${BUNDLE_DAILY_AD}"
Debug "Bundle: ${BUNDLE_DAILY_MANUAL}"
Fetch_HF_List "today"
HF_ORDER=0

for line in $(cat ${HF_LIST}); do
	HF_ORDER=$(expr ${HF_ORDER} + 1)
	
	if [ "$(is_AD ${line})" == "YES" ]; then
		Debug "Create_Daily_Bundle @ ${line} [AD]"
		echo "INSERT INTO HOTFIX_BUNDLES (BUNDLE_NAME, BUNDLE_DESC, UNIQUE_ID, ORDER_NUM, SYS_CREATION_DATE, APPLICATION_ID) VALUES ('${BUNDLE_DAILY_AD}', '${BUNDLE_DAILY_AD}_SCRIPT', ${line}, ${HF_ORDER}, SYSDATE, 'HF');" >> ${SQL_BUNDLE_DAILY_AD}
	else
		Debug "Create_Daily_Bundle @ ${line} [MANUAL]"
		echo "INSERT INTO HOTFIX_BUNDLES (BUNDLE_NAME, BUNDLE_DESC, UNIQUE_ID, ORDER_NUM, SYS_CREATION_DATE, APPLICATION_ID) VALUES ('${BUNDLE_DAILY_MANUAL}', '${BUNDLE_DAILY_MANUAL}_SCRIPT', ${line}, ${HF_ORDER}, SYSDATE, 'HF');" >> ${SQL_BUNDLE_DAILY_MANUAL}
	fi
done

Run_SQL_Statement ${SQL_BUNDLE_DAILY_AD}
Run_SQL_Statement ${SQL_BUNDLE_DAILY_MANUAL}
}

######################################
# Create Bundle - Full
######################################
Create_Full_Bundle() {
Debug "Bundle: ${BUNDLE_FULL}"
Fetch_HF_List "all"

cp ${HF_LIST} ${BUNDLE_LIST}

Debug "Adjust HFs on ${BUNDLE_FULL}"
Fetch_HF_List "bundle"
for line in $(cat ${HF_LIST}); do
	Debug "Removing HF#${line} [EXISTS]"
	sed -i "/${line}/d" ${BUNDLE_LIST}
done

Debug "Adjust HFs on ${BUNDLE_FULL}"
Fetch_HF_List "rejected"
for line in $(cat ${HF_LIST}); do
	Debug "Removing HF${line} [REJECTED]"
	sed -i "/${line}/d" ${BUNDLE_LIST}
	echo "DELETE FROM hotfix_bundles WHERE bundle_name = '${BUNDLE_FULL}' AND unique_id = '${line}';" >> ${SQL_BUNDLE_REJECTED}
done

Run_SQL_Statement ${SQL_BUNDLE_REJECTED}

HF_ORDER=$(Latest_HF_Order)

for line in $(cat ${BUNDLE_LIST}); do
	HF_ORDER=$(expr ${HF_ORDER} + 1)

	Debug "Create_Full_Bundle @ ${line}"
	echo "INSERT INTO HOTFIX_BUNDLES (BUNDLE_NAME, BUNDLE_DESC, UNIQUE_ID, ORDER_NUM, SYS_CREATION_DATE, APPLICATION_ID) VALUES ('${BUNDLE_FULL}', '${BUNDLE_FULL}_SCRIPT', ${line}, ${HF_ORDER}, SYSDATE, 'HF');" >> ${SQL_BUNDLE_FULL}
done

Run_SQL_Statement ${SQL_BUNDLE_FULL}
}

######################################
# End
######################################
End_Script() {
echo "Bundle: ${BUNDLE_DAILY_AD} | $(egrep -c '^INSERT' ${SQL_BUNDLE_DAILY_AD}) HF(s)"
echo "Bundle: ${BUNDLE_DAILY_MANUAL} | $(egrep -c '^INSERT' ${SQL_BUNDLE_DAILY_MANUAL}) HF(s)"
echo "Bundle: ${BUNDLE_FULL} | $(egrep -c '^INSERT' ${SQL_BUNDLE_FULL}) HF(s)"

Debug "End\n\n"
rm /tmp/$(basename $0)*
exit 0
}

######################################
# MAIN
######################################
if [ $# -lt 1 ]; then
	Usage 1
fi

HF_VERSION=$1
BUNDLE_FULL="$(echo ${PREFIX_NAME_BUNDLE_FULL} | sed "s/%version%/${HF_VERSION}/g")"
BUNDLE_DAILY_AD="$(echo ${PREFIX_NAME_BUNDLE_DAILY} | sed "s/%version%/${HF_VERSION}/g")_AD_$(date +%Y%m%d)"
BUNDLE_DAILY_MANUAL="$(echo ${PREFIX_NAME_BUNDLE_DAILY} | sed "s/%version%/${HF_VERSION}/g")_MANUAL_$(date +%Y%m%d)"

Debug "Main @ Starting"
Debug "Main @ Version: ${HF_VERSION}"

Create_Daily_Bundle

Create_Full_Bundle

Delete_Old_Bundles

End_Script
