#!/bin/ksh -u
##################################### INIT  SECTION ##################################
# NAME        : Exec_StorageCleanup.ksh
# DESCRIPTION : Calls Storage_Cleanup.ksh for each product and send output via email
#
# USAGE       : Exec_StorageCleanup.ksh
# DATE        : 23-FEB-16
# Created By  : Willian Costa
######################################################################################

DAYS=5
DL_FROM='vivtools@indlin3362'
DL_TO='VIVODCCInfraMPSINT@int.amdocs.com'
DL_CC='willian.costa@amdocs.com'
DL_BCC=''
MAIL_SUBJECT='Storage Cleanup Report'
TIME_STAMP=`date "+%d %b %Y"`
MAIL_BODY=''
MAIL_FL=StorageCleanupReport.txt

touch $MAIL_FL
for p in ABP CRM OMS AMSS WSF
do
	cd /vivnas/viv/vivtools/Scripts/filesystem/StorageCleanup
	touch $p.txt
	./Storage_Cleanup.ksh $p >> $p.txt
done

for prod in ABP CRM OMS AMSS WSF
do
	prod_file="$prod.txt"
	print "=======================
$prod
=======================" >> $MAIL_FL
	
	cat $prod_file | grep "removed." >> $MAIL_FL
	COUNT=$(grep -ic 'removed.' $prod_file)
	print "
	$COUNT  STORAGE(s) removed.

	" >> $MAIL_FL
	if [[ -e "$prod_file" ]]
	then
		rm -f $prod_file
	fi
done

FS=`df -h |grep XPISTORAGE |awk '{print $6}'`
FS_USED=`df -h |grep XPISTORAGE |awk '{print $5}'`
FS_AVAIL=`df -h |grep XPISTORAGE |awk '{print $4}'`

/usr/lib/sendmail -t <<EOF
To: ${DL_TO}
Cc: ${DL_CC}
From: ${DL_FROM}
Subject: ${MAIL_SUBJECT} ${TIME_STAMP}

PFB Storage Cleanup Report

=======================
STORAGE NFS USAGE
=======================
${FS} is using ${FS_USED} with ${FS_AVAIL} available.

* BELOW STORAGES WERE OLDER THAN ${DAYS} DAYS AND WERE NOT IN USE.

$(cat ${MAIL_FL})

Regards,
VIVO Infra Team

EOF
rm -f $MAIL_FL
