#!/bin/ksh

##########################################################################
#  _____________________  _________
# ___    |__  __ \__  / / /___  _/
# __  /| |_  / / /_  /_/ / __  /
# _  ___ |  /_/ /_  __  / __/ /
# /_/  |_/_____/ /_/ /_/  /___/
#
# Name: RSYNC_Transfer.ksh
#
# Transfer files via rsync using proxy via gateway
#
# Programmer: Antonio Ideguchi (hantonio)
##########################################################################

###########################################
#        RSYNC TRANSFER
###########################################
RSYNC_Transfer() {
        SRC=$1
        DST=$2
        DSTPATH=$3
        GTW_SERVER=$4
        LOG=$5
        ARGUMENTS=$6

        MKDIRCMD="mkdir -p "$DSTPATH" && rsync"
        COUNT=10
	echo "GATEWAY: ${GTW_SERVER}"
	PARAMETERS="ssh -T -c arcfour -x -o \"ProxyCommand ssh -c arcfour -x -o Compression=no -x $GTW_SERVER exec nc %h %p 2>/dev/null \""
	echo "PARAMETERS: ${PARAMETERS}"

	while [[ $COUNT -gt 0 ]]
        do        
		#rsync ${ARGUMENTS} -e "ssh -T -c arcfour -x -o "ProxyCommand ssh -c arcfour -x -o Compression=no -x `echo $GTW_SERVER` exec nc %h %p 2>/dev/null ""  ${SRC}/* ${DST}:${DSTPATH}
	        rsync $ARGUMENTS -e "$PARAMETERS" ${SRC}/* ${DST}:${DSTPATH}
		if [ "$?" = "0" ]; then
                        echo "Completed successfully!";
                        break;
                else
                        echo "ERROR: Connection failure. Retrying in a minute...";
                        (( COUNT -= 1 ))
                        echo "Remaining $COUNT retries before failing...";
                        sleep 60;
			if [[ $COUNT = 0 ]]; then
				echo "ERROR: Maximum number of retries. Please check the network connection and try again later."
				exit 1;
			fi 	
                fi
	done
}

###### MAIN

if [ "$#" -ne 6 ]; then
	echo "Usage: $(basename $0) SRC_PATH DEST_SERVER DEST_PATH GTW_SERVER LOG_FILE ARGUMENTS (-azvppPc for example)"
	exit 1
fi

RSYNC_Transfer $1 $2 $3 $4 $5 $6
