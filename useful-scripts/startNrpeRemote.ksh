#!/bin/ksh

for i in $(cat remote.lst)
do
	echo "Starting NRPE on remote host: $i"
	ssh vivtools@$i "cd /vivnas/viv/vivtools/Scripts/nagios/nrpe/bin; ./runNrpe.ksh"
done

ssh oradp@indlin3554 "cd /vivnas/viv/vivtools/Scripts/nagios/nrpe/bin; ./runNrpe.ksh"
