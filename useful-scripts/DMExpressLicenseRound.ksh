#!/bin/ksh


DistList="VIVODCCInfraMPSINT@int.amdocs.com"
FROM_MAIL=VIVODCCInfraMPSINT@int.amdocs.com

Days_Left()
{
 
 EXPIRY_DATE=`ssh ${ACCNAME}@${SERVER} -n cat /opt/dmexpress_7.9_64b/DMExpressLicense.txt | tail -3 | grep DMExpress | cut -d ' ' -f4`

 timestamp=`date | awk -F " " '{print $2" "$3","" "$6}'`
 d1=$(date -d "$EXPIRY_DATE" +%s)
 d2=$(date -d "$timestamp" +%s)
 DAYS_LEFT=$(( (d1 - d2) / 86400 ))
 
 if [ $DAYS_LEFT -lt "15" ] && [ $DAYS_LEFT -ne '0'  ]
 then
 echo "On Server $SERVER  EXPIRY_DATE = $EXPIRY_DATE Days_Left= $DAYS_LEFT " >> $REPORT_FILE
 fi
}


iPATH="/vivnas/viv/vivtools/Scripts/License_Checker/DMExpressLicenseCheck/"
SERVER_LIST="/vivnas/viv/vivtools/Scripts/License_Checker/DMExpressLicenseCheck/servers.lst"
REPORT_FILE="/vivnas/viv/vivtools/Scripts/License_Checker/DMExpressLicenseCheck/status.txt"

STATUS="All Licenses Are OK"
ACCNAME="vivtools"


for SERVER in `cat ${SERVER_LIST}`
do
     Days_Left
done

  if [[ -s $REPORT_FILE ]]
   then
	cat $REPORT_FILE | /bin/mailx -s "VIVO - DMExpressLicense Report: ${STATUS}"  "${DistList}" -- -r ${FROM_MAIL}
   fi

echo $REPORT_FILE
rm -f $REPORT_FILE
