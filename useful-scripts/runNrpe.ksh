#!/bin/ksh

export LD_LIBRARY_PATH=/vivnas/viv/vivtools/Scripts/nagios/openssl/lib:$LD_LIBRARY_PATH
./nrpe -c ../etc/nrpe.cfg -d
sleep 1

NRPE_PID=$(pgrep nrpe) 
echo $NRPE_PID >  ./logs/$(hostname)_nrpe.pid
echo "NRPE has started with PID ${NRPE_PID}."

exit 0
