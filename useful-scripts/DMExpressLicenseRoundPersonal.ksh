#SSH="/usr/bin/ssh -o StrictHostKeyChecking=no -o BatchMode=yes"
SSH="/usr/bin/ssh"
DistList="vijaysa@amdocs.com, "
#DistList=" KCellInfraIntegration@int.amdocs.com, "
FROM_MAIL=amdocs.com

SERVER_LIST="/vivnas/viv/vivtools/Scripts/DMExpressLicenseCheck/servers.lst"
REPORT_FILE="/vivnas/viv/vivtools/Scripts/DMExpressLicenseCheck/status.txt"
echo "" > $REPORT_FILE
STATUS="All Licenses Are OK"

for SERVER in `cat ${SERVER_LIST}`
do
	DAYS_LEFT=`ssh -n tooladm@${SERVER} '. ./.profile 1>/dev/null 2>&1;cd /vivnas/viv/vivtools/Scripts/DMExpressLicenseCheck;./DMExpressLicenseCheck.ksh'`
	echo "On Server $SERVER Days_Left=$DAYS_LEFT" >> $REPORT_FILE
	echo "On Server $SERVER Days_Left=$DAYS_LEFT"
	if [ $DAYS_LEFT -lt 14 ] 
	then
		STATUS="There is a Problem"
	fi
done
cat $REPORT_FILE | /bin/mailx -s "VIVO - DMExpressLicense Report: ${STATUS}"  "${DistList}" -- -r ${FROM_MAIL}
