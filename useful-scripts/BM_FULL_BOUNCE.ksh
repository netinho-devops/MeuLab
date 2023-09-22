#!/usr/bin/env ksh

stop() {
print "
delete TABLE_BPM_LM_CONNECTION;
delete TABLE_BPM_LM_SERVER;
commit;" | sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} > /dev/null 2>&1

print "
update AR1_CONTROL set SHUTDOWN_FLAG='Y';
commit;" | sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} > /dev/null 2>&1

sleep 10

pgrep -U $USER amc_mro | xargs kill -9 2> /dev/null
for SEMAPHORE in $(ipcs -s | grep $USER | awk '{ print $2 }'); do ipcrm -s ${SEMAPHORE} > /dev/null 2>&1; done
for MEMORY in $(ipcs -m | grep $USER | awk '{ print $2 }'); do ipcrm -m ${MEMORY} > /dev/null 2>&1; done
for QUEUE in $(ipcs -q | grep $USER | awk '{ print $2 }'); do ipcrm -q ${QUEUE} > /dev/null 2>&1; done

PROCESS_LIST="gcpf1fwcApp,bl1bfextract,bl1rqslsnr,RunJobs"
for process in $(echo ${PROCESS_LIST} | tr ',' '\n'); do
	pgrep -U $USER ${process} | xargs kill -9 2> /dev/null
done

echo DOWN
}

ping() {
_result=$(print "
SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
select count(*) from TABLE_BPM_LM_CONNECTION;
select count(*) from TABLE_BPM_LM_SERVER;
" | sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} | egrep -v "^#|^$" | sed -e 's/^[ \t]*//' | grep -c 0)

if [ ${_result} -eq 0 ]; then
	echo UP
	return 0
else
	echo DOWN
	return 1
fi
}

start() {
	echo UP
}

$1
return $?
