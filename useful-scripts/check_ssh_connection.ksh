#!/usr/bin/ksh

getData()
{
sqlplus -s tooladm/tooladm@BS9INF<<EOF
set head off feedback off
set lines 100
set pages 0
spool ${1}_envsss.txt
select distinct signature from ENSPOOL where PRODUCT like '${1}';
spool off
EOF
}

check_connection()
{
while read env
do

ssh -n -o PasswordAuthentication=no ${env} ' ' 2>/dev/null
if [ $? -eq 0 ]; then
	# Connection OK
	echo "">/dev/null	
else
	printf "${env}\n" >>lists.txt
fi

done<${1}_envsss.txt
}
rm -rf ABP_envsss.txt CRM_envsss.txt OMS_envsss.txt AMSS_envsss.txt lists.txt
getData ABP >/dev/null 2>&1
getData CRM >/dev/null 2>&1
getData OMS >/dev/null 2>&1
getData AMSS >/dev/null 2>&1

check_connection ABP
check_connection CRM
check_connection OMS
check_connection AMSS
