#!/usr/bin/ksh
server_list=`cat <<EOF
illin1336
illin1360
illin1391
illin1392
illin1393
illin1394
illin1396
illin1397
illin1480
illin1482
illin1493
illin1579
illin1580
illin1581
illin1798
illin1799
illin1805
EOF`

for i in $server_list
do

	maestro_user=`echo $i | grep -oE '[[:digit:]]+[^ ]*$'`;
	maestro_user=mstl${maestro_user};
	
	ssh -n -o PasswordAuthentication=no ${maestro_user}@${i} ' ' 2>/dev/null
	if [ $? -eq 0 ]; then
		
		ssh -n ${maestro_user}@${i} ' 
			2>&1 >/dev/null;
			cd ${HOME}/TWS/stdlist;
			HOST=`hostname`;
			if [ $? -eq 0 ]; then
				rm -rf $(find ./ -maxdepth 1 -mtime +2) 2>&1 >/dev/null;
			fi
			cd traces;
			if [ $? -eq 0 ]; then
				rm -rf $(find ./ -maxdepth 1 -mtime +2) 2>&1 >/dev/null;
			fi
			';	
	else
		printf "\nAuthentication Failure for Maestro Account : ${maestro_user}@${i}\n";
	fi

done
