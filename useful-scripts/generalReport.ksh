#!/bin/ksh

NAGIOS_HOST=$1
NAGIOS_PORT=$2
TARGET_RECIPIENT=$3

if [ $# -lt 3 ]
then
	echo "$(basename $0) NAGIOS_HOST NAGIOS_PORT TARGET_RECIPIENT"
	exit 1
fi

WGET_PARAM="--adjust-extension --span-hosts --backup-converted --page-requisites"

echo "Getting General Report..."
/usr/bin/wget -v ${WGET_PARAM} --user nagiosadmin --password 'nagios' -O ./`date +%Y%m%d`-report.html "http://${NAGIOS_HOST}:${NAGIOS_PORT}/nagios/cgi-bin/status.cgi?host=all"

echo "Sending e-mail"

cat << EOF - $(date +%Y%m%d)-report.html | /usr/sbin/sendmail -t
From: hantonio@amdocs.com
To: ${TARGET_RECIPIENT}
Subject:Nagios Report $(date +%d-%m-%Y)
Content-type: text/html

EOF

echo "Message sent."
