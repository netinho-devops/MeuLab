#!/usr/bin/ksh


ENV_NUMBER=$1
VERSION=$2

   ssh amdocs@10.33.200.219 "ssh vivtools@vlty0532sl ' . ./.profile >/dev/null 2>&1 ; cd /vivnas/viv/vivtools/Scripts;rafaerod/GenerateEnvCheckMail.ksh ${ENV_NUMBER} ${VERSION} UAT VIVO ${EMAIL} '" | /usr/sbin/sendmail -t
