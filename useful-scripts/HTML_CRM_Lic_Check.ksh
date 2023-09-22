#!/bin/ksh

SCRIPTS_HOME=${HOME}/scripts/License_Checker/CRM_Lic_Alert/
PROPERTY_FILE=${SCRIPTS_HOME}/CRM_lists
LOG_FILE=${SCRIPTS_HOME}/tmp/Lic_Check
mailfile=${SCRIPTS_HOME}/tmp/mail_file
flag=0
#rm $LOG_FILE
echo 'Hi All,<br/> Please check  the status of the CRM license on given environments.<br/> Please take necessary Action.<br/></br> ' >>${mailfile}
echo '<table width="1200" border="1" style="font-family:Tahoma;font-size:15px; color:#60C" cellspacing="0" >' >> ${mailfile}

echo '<tr><td scope="col" style="width:150px" align="center" bgcolor="#BFC9D9">Environment</td><td scope="col" style="width:150px" align="center" bgcolor="#BFC9D9">Host</td><td scope="col" style="width:180px" align="center" bgcolor="#BFC9D9">Expiry Date</td><td scope="col" style="width:100px" align="center" bgcolor="#BFC9D9">Days Left</td><td scope="col" style="width:500px" align="center" bgcolor="#BFC9D9">Remark</td></tr>' >> ${mailfile}

for i in `grep "^lic." ${PROPERTY_FILE}| cut -d"." -f2`
do
DB_SID=$i
DB_HOST=`tnsping ${DB_SID} | grep host | cut -d"(" -f5 | cut -d")" -f1 | cut -d'=' -f2`

DB_CONNECTION_STATUS=`${ORACLE_HOME}/bin/sqlplus -s -L sa/sa@${DB_SID} << eof
spool ${SCRIPTS_HOME}/tmp/lic.txt
@${SCRIPTS_HOME}/Check_Lic.sql
spool off;
eof`
if [[ $? != 0 ]]
then
Remark="Connection couldNot established to ${DB_SID}"
EXPIRY_DATE=000000000
DAYS_LEFT=0000000
echo "Connection couldNot established to $DB_HOST:$DB_CONNECTION_STATUS "
else
EXPIRY_DATE=$(tail -1 ${SCRIPTS_HOME}/tmp/lic.txt | cut -d" " -f1)
#echo "$EXPIRY_DATE"
DAYS_LEFT=`${SCRIPTS_HOME}/getdatediff.pl $EXPIRY_DATE`
#echo "$DAYS_LEFT"
		if [ $DAYS_LEFT -le 15  ]
		then
		if [ $DAYS_LEFT -le 0 ]
		then
			Remark="!!Warning!! CRM License Expired Please Renew It" 
		else
		
		Remark="!!Warning!!CRM License is going to expire soon. Please renew it!!"	
		fi
		else
		Remark="CRM license is OK"	
		fi
fi
echo "${DB_SID}#$DB_HOST#$EXPIRY_DATE#$DAYS_LEFT#\"$Remark\" " >>$LOG_FILE

echo '<tr><td  scope="col" style="width:200px;color:black" align="center">'${DB_SID}'</td>'  >> ${mailfile}
echo '<td  scope="col" style="width:200px;color:black" align="center">'$DB_HOST'</td>'  >> ${mailfile}
echo '<td scope="col" style="width:200px;color:black" align="center">'$EXPIRY_DATE'</td>' >> ${mailfile}
echo '<td scope="col" style="width:200px;color:black" align="center">'$DAYS_LEFT'</td>' >> ${mailfile}
if [ $DAYS_LEFT -le 15 ]
                then
echo '<td scope="col" style="width:200px;color:red" align="center">'$Remark'</td>' >> ${mailfile}
		flag=1
		else
echo '<td scope="col" style="width:200px;color:green" align="center">'$Remark'</td>' >> ${mailfile}
		 	
		fi
echo '</tr>' >> ${mailfile}


rm ${SCRIPTS_HOME}/tmp/lic.txt
done

echo '</table>' >> ${mailfile}
echo '<br/><br/>' >> ${mailfile} 
echo '<br/> Thanks and regards <br/> Infra Team ' >> ${mailfile}
x=`cat ${mailfile}`
day=`date | cut -d " " -f 1`
echo $day
echo $flag		
if [ $flag -eq 1 ]  ||  [ "$day" = "Mon" ]
		then
		
/usr/sbin/sendmail  BSSPackInfraInt@int.amdocs.com <<EOF
From:BSSPackInfraInt@amdocs.com 
To:BSSPackInfraInt@int.amdocs.com
Subject:BSS9:CRM: License Expiry Report.
Content-Type: text/html; charset="us-ascii"
<html>
<body>
<p>
<font style="font-family:Tahoma; font-size:15px; color:#60C" >
$x
</p>
</font>
</body>
</html>
EOF

		fi


rm ${mailfile}

