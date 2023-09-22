#/bin/ksh

EXPIRY_DATE=`cat /opt/dmexpress_7.9_64b/DMExpressLicense.txt | tail -3 | head -1  | grep DMExpress | cut -d ' ' -f4`

DAYS_LEFT=''
timestamp=`date | awk -F " " '{print $2" "$3","" "$6}'`
d1=$(date -d "$EXPIRY_DATE" +%s)
d2=$(date -d "$timestamp" +%s)
DAYS_LEFT=`$(( (d1 - d2) / 86400 ))`

Days_Left=$DAYS_LEFT" >>/vivnas/viv/vivtools/Scripts/License_Checker/DMExpressLicenseCheck/status.txt
#DAYS_LEFT=`/vivnas/viv/vivtools/Scripts/License_Checker/DMExpressLicenseCheck/getdatediff.pl $EXPIRY_DATE`
#DAYS_LEFT=`$HOME/Scripts/License_Checker/DMExpressLicenseCheck/getdatediff.pl $EXPIRY_DATE`

