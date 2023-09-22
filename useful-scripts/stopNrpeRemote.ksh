#!/bin/ksh

for i in $(cat remote.lst)
do
    echo "Stopping NRPE on remote host: $i"
	PARAMETER="cat /vivnas/viv/vivtools/Scripts/nagios/nrpe/bin/logs/$(echo $i)_nrpe.pid"
    COMMAND="kill -15 \$(${PARAMETER})"
	echo $COMMAND;
	ssh vivtools@$i "$COMMAND"
done
