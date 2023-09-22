#!/bin/ksh -xv

Version=$1
Delivery_link=$2
#Delivery link shoudl be with full path
Account=$3
Server=$4

Reader_Server=bssdlv@illin1339
Writer_Server=bssdel@illin1339


####### XPI  # amdocs-installer.tar ###########################################################

xpiNumber=`ssh ${Account}@${Server} -n "cd genesisTmpDir; cat line_cxpi.properties | grep cxpi.drop.number | grep PB | cut -d= -f2"`
ssh $Writer_Server -n "mkdir -p ${Delivery_link}/INT/Packages/XPI/${xpiNumber}"
cd /XPISTORAGE/CORE/XPI/64/${xpiNumber}
scp amdocs-installer.tar ${Writer_Server}:${Delivery_link}/INT/Packages/XPI/${xpiNumber}

